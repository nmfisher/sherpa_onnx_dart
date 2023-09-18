import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx.dart';
import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx_platform_interface.dart';
import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSherpaOnnxPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSherpaOnnxPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSherpaOnnxPlatform initialPlatform =
      FlutterSherpaOnnxPlatform.instance;

  test('$MethodChannelFlutterSherpaOnnx is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSherpaOnnx>());
  });

  test('getPlatformVersion', () async {
    FlutterSherpaOnnx flutterVoskPlugin = FlutterSherpaOnnx();
    MockFlutterSherpaOnnxPlatform fakePlatform =
        MockFlutterSherpaOnnxPlatform();
    FlutterSherpaOnnxPlatform.instance = fakePlatform;

    expect(await flutterVoskPlugin.getPlatformVersion(), '42');
  });
}
