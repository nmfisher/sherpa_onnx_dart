
import 'flutter_sherpa_onnx_platform_interface.dart';

class FlutterSherpaOnnx {
  Future<String?> getPlatformVersion() {
    return FlutterSherpaOnnxPlatform.instance.getPlatformVersion();
  }
}
