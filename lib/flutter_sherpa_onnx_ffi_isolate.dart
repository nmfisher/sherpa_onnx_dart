import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

import './generated_bindings.dart';
import 'package:flutter/services.dart';

class FlutterSherpaOnnxFFIIsolateRunner {
  final SendPort _setupPort;

  final SendPort _createdRecognizerPort;
  final SendPort _resultPort;

  late final NativeLibrary _lib;

  Pointer<Float>? _bufferPtr;

  final double chunkLengthInSecs;
  int? sampleRate;

  Pointer<SherpaOnnxOnlineRecognizer>? _recognizer;
  Pointer<SherpaOnnxOnlineStream>? _stream;

  FlutterSherpaOnnxFFIIsolateRunner(this._setupPort,
      this._createdRecognizerPort, this._resultPort, this.chunkLengthInSecs) {
    var dataPort = ReceivePort();
    var createRecognizerPort = ReceivePort();
    var killRecognizerPort = ReceivePort();

    var shutdownPort = ReceivePort();

    _setupPort.send([
      dataPort.sendPort,
      createRecognizerPort.sendPort,
      killRecognizerPort.sendPort,
      shutdownPort.sendPort,
    ]);

    killRecognizerPort.listen(_onKillRecognizerCommandReceived);
    createRecognizerPort.listen(_onCreateRecognizerCommandReceived);

    dataPort.listen(_onWaveformDataReceived);

    shutdownPort.listen((message) {
      if (message) {
        _onKillRecognizerCommandReceived(null);

        if (_bufferPtr != null) {
          calloc.free(_bufferPtr!);
        }
        Isolate.current.kill();
      }
    });

    _lib = NativeLibrary(Platform.isAndroid || Platform.isLinux
        ? DynamicLibrary.open("libflutter_sherpa_onnx_plugin.so")
        : DynamicLibrary.process());
  }

  int _chunkLengthInSamples = 0;

  void _onCreateRecognizerCommandReceived(dynamic args) async {
    if (_recognizer != null || _stream != null) {
      throw Exception(
          "Recognizer already exists, make sure to call kill first.");
    }

    this.sampleRate = (args[0] as double).toInt();

    var newChunkLengthInSamples = (chunkLengthInSecs * sampleRate!).toInt();
    if (newChunkLengthInSamples != _chunkLengthInSamples) {
      _chunkLengthInSamples = newChunkLengthInSamples;

      if (_bufferPtr != null) {
        calloc.free(_bufferPtr!);
      }

      _bufferPtr = calloc<Float>(_chunkLengthInSamples * 3);
    }

    String tokensPath = args[1];
    String encoderPath = args[2];
    String decoderPath = args[3];
    String joinerPath = args[4];

    var config = calloc<SherpaOnnxOnlineRecognizerConfig>();

    config.ref.model_config.debug = 1;
    config.ref.model_config.num_threads = 1;
    var provider = "cpu";
    var decodingMethod = "greedy_search";
    config.ref.model_config.provider = provider.toNativeUtf8().cast<Char>();

    config.ref.decoding_method = decodingMethod.toNativeUtf8().cast<Char>();

    config.ref.max_active_paths = 4;

    config.ref.feat_config.sample_rate = 16000;
    config.ref.feat_config.feature_dim = 80;

    config.ref.enable_endpoint = 1;
    config.ref.rule1_min_trailing_silence = 2.4;
    config.ref.rule2_min_trailing_silence = 1.2;
    config.ref.rule3_min_utterance_length = 300;

    config.ref.model_config.model_type = nullptr;
    config.ref.model_config.tokens = tokensPath.toNativeUtf8().cast<Char>();
    config.ref.model_config.paraformer.encoder = nullptr;
    config.ref.model_config.paraformer.decoder = nullptr;
    config.ref.model_config.transducer.encoder =
        encoderPath.toNativeUtf8().cast<Char>();
    config.ref.model_config.transducer.decoder =
        decoderPath.toNativeUtf8().cast<Char>();
    config.ref.model_config.transducer.joiner =
        joinerPath.toNativeUtf8().cast<Char>();

    var hotwords = "";
    config.ref.hotwords_file = hotwords.toNativeUtf8().cast<Char>();
    config.ref.hotwords_score = 1.0;

    _recognizer = _lib.CreateOnlineRecognizer(config);
    _stream = _lib.CreateOnlineStream(_recognizer!);

    if (_recognizer != nullptr && _stream != nullptr) {
      _createdRecognizerPort.send(true);
      print("Created recognizer & stream");
    } else {
      _createdRecognizerPort.send(false);
    }
  }

  int _readPointer = 0;
  int _writePointer = 0;

  void _onWaveformDataReceived(dynamic data) async {
    var tl = Int16List.sublistView(Uint8List.fromList(data));

    for (int i = 0; i < tl.length; i++) {
      _bufferPtr!.elementAt(_writePointer + i).value = tl[i] / 32768.0;
    }
    _writePointer += tl.length;

    if (_writePointer - _readPointer < _chunkLengthInSamples) {
      return;
    }

    var floatPtr = _bufferPtr!.elementAt(_readPointer);

    _lib.AcceptWaveform(_stream!, sampleRate!, floatPtr, _chunkLengthInSamples);
    while (_lib.IsOnlineStreamReady(_recognizer!, _stream!) == 1) {
      _lib.DecodeOnlineStream(_recognizer!, _stream!);
    }

    var result = _lib.GetOnlineStreamResult(_recognizer!, _stream!);

    _readPointer += _chunkLengthInSamples;
    if (_readPointer == _chunkLengthInSamples * 2) {
      _readPointer = 0;
    }

    if (_writePointer > _chunkLengthInSamples * 2) {
      var diff = _writePointer - (_chunkLengthInSamples * 2);
      for (int i = 0; i < diff; i++) {
        _bufferPtr!.elementAt(i).value =
            _bufferPtr!.elementAt((_chunkLengthInSamples * 2) + diff).value;
      }
      _writePointer = diff;
    }
    if (result != nullptr) {
      if (result.ref.json != nullptr) {
        _resultPort.send(result.ref.json.cast<Utf8>().toDartString());
      }
      _lib.DestroyOnlineRecognizerResult(result);
    }

    if (_lib.IsEndpoint(_recognizer!, _stream!) == 1) {
      _lib.Reset(_recognizer!, _stream!);
    }
  }

  void _onKillRecognizerCommandReceived(_) {
    if (_stream != null) {
      _lib.DestroyOnlineStream(_stream!);
    }
    if (_recognizer != null) {
      _lib.DestroyOnlineRecognizer(_recognizer!);
    }
    _stream = null;
    _recognizer = null;
  }

  static void create(List args) {
    SendPort setupPort = args[0];
    SendPort createdRecognizerPort = args[1];
    SendPort resultPort = args[2];
    double chunkLengthInSecs = args[3];
    BackgroundIsolateBinaryMessenger.ensureInitialized(
        args[4] as RootIsolateToken);
    var runner = FlutterSherpaOnnxFFIIsolateRunner(
        setupPort, createdRecognizerPort, resultPort, chunkLengthInSecs);
  }
}
