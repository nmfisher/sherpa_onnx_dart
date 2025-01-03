import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_ffi_asset_helper/flutter_ffi_asset_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:sherpa_onnx_dart/sherpa_onnx_dart.dart';
import 'package:wave_builder/wave_builder.dart';
import 'package:record/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _micConfigured = false;

  bool _hasRecognizer = false;

  StreamSubscription<ASRResult>? _listener;
  final _results = <ASRResult>[];
  String? _partial;
  String? _decoded;
  late double microphoneSampleRate;

  late SherpaOnnx plugin;

  Stream<Uint8List?>? _mic;

  @override
  void initState() {
    plugin = SherpaOnnx();
    plugin.result.listen((result) {
      var string = _partial = result.words.map((w) => w.word).join("");
      if (result.isFinal) {
        _partial = null;
        _decoded = string;
      } else {
        _partial = string;
        _decoded = null;
      }
      setState(() {});
    });

    super.initState();
  }

  void _configureMicrophone() async {
    final record = AudioRecorder();
    const config =
        RecordConfig(encoder: AudioEncoder.pcm16bits, numChannels: 1);
    microphoneSampleRate = config.sampleRate.toDouble();
    _mic = await record.startStream(config);
    _mic!.listen(_handleMicrophoneInput);

    setState(() {
      _micConfigured = true;
    });
  }

  void createRecognizer(double sampleRate) async {
    var helper = FlutterFfiAssetHelper();
    await rootBundle.loadString("assets/model/tokens.txt");
    var tokensPath = await helper.assetToFilepath("assets/model/tokens.txt");
    var encoderPath = await helper.assetToFilepath(
        "assets/model/encoder-epoch-99-avg-1.int8.with_runtime_opt.ort");
    var decoderPath = await helper.assetToFilepath(
        "assets/model/decoder-epoch-99-avg-1.int8.with_runtime_opt.ort");
    var joinerPath = await helper.assetToFilepath(
        "assets/model/joiner-epoch-99-avg-1.int8.with_runtime_opt.ort");
    await plugin.createRecognizer(
      sampleRate,
      tokensPath,
      encoderPath,
      decoderPath,
      joinerPath,
      chunkLengthInSecs: 0.1,
    );

    setState(() {
      _decoded = "";
      _hasRecognizer = true;
    });
  }

  void destroyRecognizer() async {
    await stopListening();
    await plugin.destroyRecognizer();
    setState(() {
      _hasRecognizer = false;
    });
  }

  bool _listening = false;

  void _handleMicrophoneInput(Uint8List? data) async {
    if(data == null || !_listening) {
      return;
    }
    plugin.acceptWaveform(data);
  }

  ///
  /// Immediately ignore all audio from the microphone.
  ///
  Future stopListening() async {
    print("Pausing pipeline");
    _listening = false;
  }

  ///
  /// Instructs the underlying pipeline to start (or resume) processing data from the microphone.
  ///
  void listen() async {
    print("Unpausing pipeline");
    _listening = true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            body: Wrap(children: [
              ElevatedButton(
                  onPressed: () {
                    _configureMicrophone();
                  },
                  child: const Text("Initialize microphone")),
              ElevatedButton(
                  child: const Text("Create Recognizer"),
                  onPressed: !_hasRecognizer
                      ? () async {
                          createRecognizer(microphoneSampleRate);
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Create stream (no hotwords)"),
                  onPressed: _hasRecognizer
                      ? () async {
                          await plugin.createStream(null);
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Create stream (hotwords)"),
                  onPressed: _hasRecognizer
                      ? () async {
                          await plugin.createStream(["会 话"]);
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Start microphone"),
                  onPressed: _hasRecognizer && _micConfigured
                      ? () async {
                          _results.clear();
                          listen();
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Play source audio from transcription"),
                  onPressed: _results.isNotEmpty
                      ? () async {
                          for (int i = 0; i < _results.length; i++) {
                            for (final word in _results[i].words) {
                              var file = File(
                                  (await getTemporaryDirectory()).path +
                                      "/test.wav");
                              print(
                                  "Word ${word.word} start: ${word.start} end: ${word.end}");
                              var waveBuilder = WaveBuilder(
                                  frequency:
                                      microphoneSampleRate.toInt(),
                                  stereo: false);
                              // var data = _results[i].getAudio(word);
                              // waveBuilder.appendFileContents(data);

                              // file.writeAsBytesSync(waveBuilder.fileBytes);

                              // final player = AudioPlayer();
                              // final comp = Completer();
                              // player.playerStateStream.listen((event) {
                              //   if (event.processingState ==
                              //       ProcessingState.completed) {
                              //     comp.complete();
                              //   }
                              // });
                              // player.setVolume(100.0);
                              // player.setFilePath(file.path, preload: true);
                              // await player.play();
                              // await comp.future;
                            }
                          }
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Destroy Recognizer"),
                  onPressed: _hasRecognizer
                      ? () async {
                          await _listener?.cancel();
                          destroyRecognizer();
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Stop listening"),
                  onPressed: _hasRecognizer
                      ? () async {
                          _listener?.cancel();
                          stopListening();
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Decode from buffer"),
                  onPressed: _hasRecognizer
                      ? () async {
                          throw Exception("TODO");
                        }
                      : null),
              ElevatedButton(
                  child: const Text("Decode from file"),
                  onPressed: _hasRecognizer
                      ? () async {
                          setState(() {
                            _decoded = "";
                          });
                          // var bd = await rootBundle.load("assets/test.wav");
                          // var decoded = await _flutterVosk.acceptWaveform(
                          //     _hasRecognizer!,
                          //     bd.buffer.asUint8List(bd.offsetInBytes));

                          // setState(() {
                          //   _decoded =
                          //       decoded?["result"] ?? decoded?["partial"];
                          // });
                          // TODO - we moved the sample project to use Transcriber rather than FlutterSherpaOnnx directly, so decodeBuffer isn't available
                        }
                      : null),
              Text("PARTIAL: $_partial"),
              Text(_decoded ?? "")
            ])));
  }
}
