import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import './generated_bindings.dart';
import 'package:flutter/services.dart';

enum RecognizerCommand { Reset, SetWords, SetLMWeight, ResetLMWeights }

class FlutterSherpaOnnxFFIIsolateRunner {
  Completer<int>? _modelLoadedCompleter;

  final _listeners = <StreamSubscription>[];

  final SendPort _setupPort;

  final SendPort _createdRecognizerPort;
  final SendPort _resultPort;

  late final NativeLibrary _lib;

  Pointer<Uint8>? _bufferPtr;

  final double chunkLengthInSecs;

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

  int _chunkLengthInBytes = 0;

  void _onCreateRecognizerCommandReceived(dynamic args) async {
    double sampleRate = args[0];

    var newChunkLengthInBytes = (chunkLengthInSecs * sampleRate * 2).toInt();
    if (newChunkLengthInBytes != _chunkLengthInBytes) {
      _chunkLengthInBytes = newChunkLengthInBytes;
      if (_bufferPtr != null) {
        calloc.free(_bufferPtr!);
      }

      _bufferPtr = calloc.allocate<Uint8>(_chunkLengthInBytes * 3);
    }

    String tokensPath = args[1];
    String encoderPath = args[2];
    String decoderPath = args[3];
    String joinerPath = args[4];
    if (_lib.flutter_sherpa_onnx_create(
            tokensPath.toNativeUtf8().cast<Char>(),
            encoderPath.toNativeUtf8().cast<Char>(),
            decoderPath.toNativeUtf8().cast<Char>(),
            joinerPath.toNativeUtf8().cast<Char>()) ==
        1) {
      _createdRecognizerPort.send(true);
      print("Model loading complete");
    } else {
      _createdRecognizerPort.send(false);
    }
  }

  int _readPointer = 0;
  int _writePointer = 0;

  void _onWaveformDataReceived(dynamic data) {
    var tl = data[1] as Uint8List;

    for (int i = 0; i < tl.length; i++) {
      _bufferPtr!.elementAt(_writePointer + i).value = tl[i];
    }
    _writePointer += tl.length;

    if (_writePointer - _readPointer < _chunkLengthInBytes) {
      return;
    }

    var result = _lib.flutter_sherpa_onnx_accept_waveform_s(
        _bufferPtr!.elementAt(_readPointer).cast<Int16>(),
        _chunkLengthInBytes ~/ 2);

    _readPointer += _chunkLengthInBytes;
    if (_readPointer == _chunkLengthInBytes * 2) {
      _readPointer = 0;
    }

    if (_writePointer > _chunkLengthInBytes * 2) {
      var diff = _writePointer - (_chunkLengthInBytes * 2);
      for (int i = 0; i < diff; i++) {
        _bufferPtr!.elementAt(i).value =
            _bufferPtr!.elementAt((_chunkLengthInBytes * 2) + diff).value;
      }
      _writePointer = diff;
    }

    var resString = result.cast<Utf8>().toDartString();
    _resultPort.send(resString);
  }

  void _onKillRecognizerCommandReceived(_) {
    _lib.flutter_sherpa_onnx_destroy();
  }

  static void create(List args) {
    SendPort setupPort = args[0];
    SendPort createdRecognizerPort = args[1];
    SendPort resultPort = args[2];
    double chunkLengthInSecs = args[3];
    var runner = FlutterSherpaOnnxFFIIsolateRunner(
        setupPort, createdRecognizerPort, resultPort, chunkLengthInSecs);
  }
}
