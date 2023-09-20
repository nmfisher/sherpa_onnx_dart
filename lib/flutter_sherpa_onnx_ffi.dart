import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx_ffi_isolate.dart';
import 'package:flutter_ffi_asset_helper/flutter_ffi_asset_helper.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FlutterSherpaOnnxFFI {
  Stream<Map> get result => _resultController.stream;
  final _resultController = StreamController<Map>.broadcast();

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
      print(result);
      _resultController.add(json.decode(result));
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

  Future createRecognizer(
      double sampleRate,
      int bufferSizeInBytes,
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

    // var tokensFilePath = await _helper.getFdFromAsset(tokensAssetPath);
    // var encoderFilePsath = await _helper.getFdFromAsset(encoderAssetPath);
    // var decoderFilePath = await _helper.getFdFromAsset(decoderAssetPath);
    // var joinerFilePath = await _helper.getFdFromAsset(joinerAssetPath);

    var dir = await getApplicationDocumentsDirectory();

    var tdata = await rootBundle.load(tokensAssetPath);
    File(dir.path + "/tokens.txt").writeAsBytesSync(tdata.buffer.asUint8List());
    var ddata = await rootBundle.load(decoderAssetPath);
    File(dir.path + "/decoder.ort")
        .writeAsBytesSync(ddata.buffer.asUint8List());
    var edata = await rootBundle.load(encoderAssetPath);
    File(dir.path + "/encoder.ort")
        .writeAsBytesSync(edata.buffer.asUint8List());
    var jdata = await rootBundle.load(joinerAssetPath);
    File(dir.path + "/joiner.ort").writeAsBytesSync(jdata.buffer.asUint8List());

    _createRecognizerPort.send([
      sampleRate,
      bufferSizeInBytes,
      chunkLengthInSecs,
      dir.path + "/tokens.txt",
      dir.path + "/encoder.ort",
      dir.path + "/decoder.ort",
      dir.path + "/joiner.ort",
    ]);

    // _createRecognizerPort.send([
    //   sampleRate,
    //   tokensFilePath,
    //   encoderFilePsath,
    //   decoderFilePath,
    //   joinerFilePath,
    // ]);
    var result = await completer.future;
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
    }
    return result;
  }

  Future destroyRecognizer() async {
    _killRecognizerPort.send(true);
    _killed = true;
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
