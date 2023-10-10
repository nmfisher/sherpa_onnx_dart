import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sherpa_onnx/audio_buffer.dart';
import 'package:flutter_sherpa_onnx/generated_bindings.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sherpa_onnx/flutter_sherpa_onnx_ffi.dart';

class Transcriber {
  late String _modelAssetPath;
  
  final int sampleRate;

  Transcriber(this._modelAssetPath, this._microphone, this.sampleRate);

  bool _loaded = false;

  bool _listening = false;

  late AudioBuffer _audioBuffer;

  final StreamController<ASRResult> _resultController =
      StreamController<ASRResult>.broadcast();
  Stream<ASRResult> get result => _resultController.stream;

  final StreamController<bool> _isListeningController =
      StreamController<bool>.broadcast();
  Stream<bool> get isListening => _isListeningController.stream;

  Stream<Float32List?> get spectrum => _spectrumController.stream;
  final _spectrumController = StreamController<Float32List?>.broadcast();
  late StreamSubscription _spectrumListener;

  late Stream<Uint8List> raw;

  late FlutterSherpaOnnxFFI plugin;

  late Stream<Uint8List> _microphone;

  final Completer<bool> _initialized = Completer<bool>();
  Future<bool> get initialized => _initialized.future;

  Future initialize() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    ));

    
    plugin = FlutterSherpaOnnxFFI();

    _audioBuffer =
        AudioBuffer(sampleRate, 30); // store 30 seconds of audio in memory
    _microphone.listen(_handleMicrophoneInput);

    plugin.result.listen((result) {
      _resultController.add(result);
    });

    _initialized.complete(true);
  }

  void _handleMicrophoneInput(Uint8List data) async {
    if (!_listening) {
      return;
    }
    if (!_audioBuffer.add(data)) {
      _audioBuffer.reset();
      _audioBuffer.add(data);
    }
    plugin.acceptWaveform(data);
  }

  ///
  /// Create a recognizer with the specified grammar.
  /// Returns false if an error is encountered.
  ///
  Future<bool> createRecognizer() async {
    if (!Platform.isLinux) {
      await plugin.createRecognizer(
          sampleRate.toDouble(),
          0.1,
          "assets/asr/tokens.txt",
          "assets/asr/encoder-epoch-99-avg-1.int8.with_runtime_opt.ort",
          "assets/asr/decoder-epoch-99-avg-1.int8.with_runtime_opt.ort",
          "assets/asr/joiner-epoch-99-avg-1.int8.with_runtime_opt.ort");

      return true;
    }
    return false;
  }

  Future destroyRecognizer() async {
    _pause();
    plugin.destroyRecognizer();
  }

  void _pause() async {
    _listening = false;
  }

  void _unpause() async {
    _listening = true;
  }

  ///
  /// Immediately ignore all audio from the microphone.
  ///
  Future stopListening() async {
    if (!_initialized.isCompleted) {
      print("AudioInputService not yet initialized, ignoring command to pause");
      return;
    }
    print("Pausing pipeline");
    _pause();
    _spectrumController.add(null);
  }

  ///
  /// Instructs the underlying pipeline to start (or resume) processing data from the microphone.
  ///
  void listen() async {
    if (!_initialized.isCompleted) {
      print(
          "AudioInputService not yet initialized, ignoring command to resume");
      return;
    }
    print("Unpausing pipeline");
    _audioBuffer.reset();
    _unpause();
  }

  void dispose() async {
    _resultController.close();
    _isListeningController.close();
    await _spectrumListener.cancel();
    await _spectrumController.close();
  }
}
