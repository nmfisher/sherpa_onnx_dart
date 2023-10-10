import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx_ffi_isolate.dart';
import 'package:flutter_ffi_asset_helper/flutter_ffi_asset_helper.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WordTranscription {
  final String word;
  final double? start;
  final double? end;

  WordTranscription(this.word, this.start, this.end);
}

class ASRResult {
  final bool isFinal;
  final List<WordTranscription> words;

  ASRResult(this.isFinal, this.words);
}

class FlutterSherpaOnnxFFI {
  Stream<ASRResult> get result => _resultController.stream;
  final _resultController = StreamController<ASRResult>.broadcast();

  Isolate? _runner;

  final _createdRecognizerPort = ReceivePort();
  late Stream _createdRecognizerPortStream =
      _createdRecognizerPort.asBroadcastStream();
  final _createdStreamPort = ReceivePort();
  late Stream _createdStreamPortStream = _createdStreamPort.asBroadcastStream();

  final _setupPort = ReceivePort();
  bool _killed = false;
  final _resultPort = ReceivePort();

  late SendPort _dataPort;
  late SendPort _createRecognizerPort;
  late SendPort _killRecognizerPort;
  late SendPort _createStreamPort;
  late SendPort _shutdownPort;

  final FlutterFfiAssetHelper _helper = FlutterFfiAssetHelper();

  FlutterSherpaOnnxFFI() {
    _setupPort.listen((msg) {
      _dataPort = msg[0];
      _createRecognizerPort = msg[1];
      _killRecognizerPort = msg[2];
      _createStreamPort = msg[3];
      _shutdownPort = msg[4];
    });
    _resultPort.listen((result) {
      var resultMap = json.decode(result);

      bool isFinal = resultMap["is_final"] == true;

      if (isFinal) {
        if (resultMap["text"].isNotEmpty) {
          var words = resultMap["tokens"]
              .map((r) => WordTranscription(r["word"], r["start"], r["end"]))
              .cast<WordTranscription>()
              .toList();
          _resultController.add(ASRResult(isFinal, words));
        }
      } else {
        if (resultMap["text"].isNotEmpty) {
          _resultController.add(ASRResult(
              isFinal, [WordTranscription(resultMap["text"], null, null)]));
        }
      }
    });

    Isolate.spawn(FlutterSherpaOnnxFFIIsolateRunner.create, [
      _setupPort.sendPort,
      _createdRecognizerPort.sendPort,
      _createdStreamPort.sendPort,
      _resultPort.sendPort,
      ServicesBinding.rootIsolateToken
    ]).then((isolate) {
      _runner = isolate;
    });
  }

  Future decodeBuffer() async {
    throw Exception("TODO");
  }

  bool _hasRecognizer = false;

  Future createRecognizer(
      double sampleRate,
      double chunkLengthInSecs,
      String tokensAssetPath,
      String encoderAssetPath,
      String decoderAssetPath,
      String joinerAssetPath) async {
    final completer = Completer<bool>();
    late StreamSubscription listener;
    listener = _createdRecognizerPortStream.listen((success) {
      completer.complete(success);
      listener.cancel();
    });

    var tokensFilePath = await _helper.assetToFilepath(tokensAssetPath);
    var encoderFilePsath = await _helper.assetToFilepath(encoderAssetPath);
    var decoderFilePath = await _helper.assetToFilepath(decoderAssetPath);
    var joinerFilePath = await _helper.assetToFilepath(joinerAssetPath);

    var dir = await getApplicationDocumentsDirectory();

    _createRecognizerPort.send([
      sampleRate,
      chunkLengthInSecs,
      tokensFilePath,
      encoderFilePsath,
      decoderFilePath,
      joinerFilePath,
    ]);

    var result = await completer.future;
    _hasRecognizer = true;
    return result;
  }

  Future createStream(List<String>? phrases) async {
    final completer = Completer<bool>();
    late StreamSubscription listener;
    listener = _createdStreamPortStream.listen((success) {
      completer.complete(success);
      listener.cancel();
    });
    _createStreamPort.send(phrases?.join("\n"));
    var result = await completer.future;
    if (result) {
      _killed = false;
    } else {
      throw Exception("Failed to create stream. Is a recognizer available?");
    }
    return result;
  }

  Future destroyRecognizer() async {
    if (_hasRecognizer) {
      _killRecognizerPort.send(true);
      _killed = true;
    }
    _hasRecognizer = false;
  }

  void acceptWaveform(Uint8List data) async {
    if (_killed) {
      return;
    }
    _dataPort.send(data);
  }

  Future dispose() async {
    _shutdownPort.send(true);
  }
}
