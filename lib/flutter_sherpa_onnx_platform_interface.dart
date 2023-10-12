import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_sherpa_onnx_method_channel.dart';

abstract class FlutterSherpaOnnxPlatform extends PlatformInterface {
  /// Constructs a FlutterSherpaOnnxPlatform.
  FlutterSherpaOnnxPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSherpaOnnxPlatform _instance = MethodChannelFlutterSherpaOnnx();

  /// The default instance of [FlutterSherpaOnnxPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSherpaOnnx].
  static FlutterSherpaOnnxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSherpaOnnxPlatform] when
  /// they register themselves.
  static set instance(FlutterSherpaOnnxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
