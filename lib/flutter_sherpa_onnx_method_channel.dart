import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_sherpa_onnx_platform_interface.dart';

/// An implementation of [FlutterSherpaOnnxPlatform] that uses method channels.
class MethodChannelFlutterSherpaOnnx extends FlutterSherpaOnnxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_sherpa_onnx');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
