import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sherpa_onnx_example/transcriber.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave_builder/wave_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Transcriber _transcriber;

  bool _ready = false;
  bool _hasRecognizer = false;
  StreamSubscription<ASRResult>? _listener;
  StreamSubscription<String>? _partialListener;
  final _results = <ASRResult>[];
  String? _partial;
  String? _decoded;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (!Platform.isLinux) {
        var bitDepth = await MicStream.bitDepth;
        var sampleRate = await MicStream.sampleRate;
        print(
            "Getting mic stream, bd is $bitDepth and sampleRate is $sampleRate");
        var mic = await MicStream.microphone(
            audioFormat: AudioFormat.ENCODING_PCM_16BIT,
            sampleRate: Platform.isMacOS ? 48000 : 16000);

        print("Got stream");

        var listener = mic!.listen((event) {});

        print("LISTENED");
        // print("Using bit depth " +
        //     (()?.toString() ?? "") +
        //     " and sample rate " +
        //     (().toString()));
        _transcriber = Transcriber("assets/asr");
        await _transcriber.initialize();

        setState(() {
          _ready = true;
        });
        listener.cancel();

        print("DONE : $mic");
      } else {
        _transcriber = Transcriber("assets/asr");
        setState(() {
          _ready = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: _ready
            ? Wrap(children: [
                ElevatedButton(
                    child: const Text("Create Recognizer"),
                    onPressed: !_hasRecognizer
                        ? () async {
                            var sampleRate = Platform.isLinux
                                ? 44100.0
                                : (await MicStream.sampleRate)!;

                            await _transcriber.createRecognizer();

                            setState(() {
                              _decoded = "";
                              _hasRecognizer = true;
                            });
                          }
                        : null),
                ElevatedButton(
                    child: const Text("Start microphone"),
                    onPressed: _hasRecognizer
                        ? () async {
                            _results.clear();
                            _transcriber.listen();
                            _listener = _transcriber.result.listen((r) {
                              _results.add(r);
                              setState(() {
                                _decoded = r.text;
                              });
                            });
                            _partialListener = _transcriber.partial.listen((p) {
                              _partial = p;
                              setState(() {});
                            });
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
                                    "Word ${word.word} start: ${word.startTime} end: ${word.endTime}");
                                var waveBuilder = WaveBuilder(
                                    frequency:
                                        (await MicStream.sampleRate)!.toInt(),
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
                            await _transcriber.destroyRecognizer();

                            setState(() {
                              _decoded = "";
                              _hasRecognizer = false;
                            });
                          }
                        : null),
                ElevatedButton(
                    child: const Text("Stop listening"),
                    onPressed: _hasRecognizer
                        ? () async {
                            _listener?.cancel();
                            await _transcriber.stopListening();
                          }
                        : null),
                ElevatedButton(
                    child: const Text("Decode from buffer"),
                    onPressed: _hasRecognizer
                        ? () async {
                            setState(() {
                              _decoded = "";
                            });
                            // _decoded = await _flutterVosk.decodeBuffer();
                            // TODO - we moved the sample project to use Transcriber rather than FlutterSherpaOnnx directly, so decodeBuffer isn't available
                            setState(() {});
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
                ElevatedButton(
                    child: const Text("Set grammar to nil"),
                    onPressed: _hasRecognizer
                        ? () async {
                            // await _flutterVosk.setGrammar(_hasRecognizer!);
                            // TODO - we moved the sample project to use Transcriber rather than FlutterSherpaOnnx directly, so decodeBuffer isn't available

                            setState(() {});
                          }
                        : null),
                Text("PARTIAL: $_partial"),
                Text(_decoded ?? "")
              ])
            : Container(),
      ),
    );
  }
}
