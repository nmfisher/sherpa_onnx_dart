import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../lib/flutter_sherpa_onnx_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Recognizer tests', () {
    test('successfully recognize from a file', () async {
      var plugin = FlutterSherpaOnnxFFI();
      await plugin.createRecognizer(
          16000,
          1024,
          0.1,
          "example/assets/asr/tokens.txt",
          "example/assets/asr/encoder-epoch-99-avg-1.int8.with_runtime_opt.ort",
          "example/assets/asr/decoder-epoch-99-avg-1.int8.with_runtime_opt.ort",
          "example/assets/asr/joiner-epoch-99-avg-1.int8.with_runtime_opt.ort");
      var data = File("example/assets/test.pcm").readAsBytesSync();
      var results = <ASRResult>[];
      plugin.result.listen((ASRResult asrResult) {
        results.add(asrResult);
      });
      for (int i = 0; i < data.length; i += 1024) {
        plugin.acceptWaveform(data.sublist(i, i + 1024));
      }
      await Future.delayed(Duration(milliseconds: 500));
      expect(results.length, 1);
    });
  });
}
