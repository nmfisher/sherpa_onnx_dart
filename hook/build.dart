// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (config, output) async {
    var logFile = File(
        "${config.packageRoot.toFilePath()}.dart_tool/sherpa_onnx_dart/log/build.log");
    if (!logFile.parent.existsSync()) {
      logFile.parent.createSync(recursive: true);
    }

    final logger = Logger("")
      ..level = Level.ALL
      ..onRecord.listen((record) => logFile.writeAsStringSync(
          "${record.message}\n",
          mode: FileMode.append,
          flush: true));

    var platform = config.targetOS.toString().toLowerCase();
    var onnxDir = "${config.packageRoot.path}/onnxruntime_prebuilt";
    var onnxLibDir = "$onnxDir/lib/$platform/";
    var libDir = "${config.packageRoot.toFilePath()}/native/lib/$platform/";

    if (platform == "macos") {
      onnxLibDir += "dynamic/";
    } else if (platform == "android") {
      libDir += "arm64-v8a/";
      onnxLibDir += "arm64-v8a/";
    }

    final packageName = config.packageName;

    final cbuilder = CBuilder.library(
      name: packageName,
      language: Language.cpp,
      assetName: '$packageName.dart',
      sources: [
        'native/src/extras.cpp',
      ],
      includes: ['native/include', 
      '$onnxDir/include'
      ],
      flags: [
        '-std=c++17',
        if (platform == "ios" || platform == "macos") ...[
          "-F$onnxLibDir",
          '-framework',
          'onnxruntime',
          '-framework',
          'Foundation',
          // "-Wl,-rpath,@loader_path",
          // "-Wl,-rpath,@loader_path/Frameworks",
          // "-Wl,-rpath,@loader_path/Contents/Frameworks/",
          // "-Wl,-rpath,@loader_path/../Frameworks",
          // "-Wl,-rpath,@loader_path/../../Frameworks",
          // "-Wl,-rpath,@executable_path/../Frameworks",
          // "-Wl,-rpath,@executable_path/Frameworks/",
          // "-Wl,-rpath,@executable_path/Contents/Frameworks/",
          // "-Wl,-rpath,@executable_path/SharedFrameworks"
        ],
        if (platform == "ios") "-mios-version-min=8.0",
        "-lkaldi-decoder-core",
        "-lsherpa-onnx-fst",
        "-lsherpa-onnx-c-api",
        "-lsherpa-onnx-core",
        "-lkaldi-native-fbank-core",
        "-lsherpa-onnx-kaldifst-core",
        "-L$libDir",
        "-force_load",
        "$libDir/libsherpa-onnx-fst.a",
        "-force_load",
        "$libDir/libsherpa-onnx-c-api.a",
        "-force_load",
        "$libDir/libsherpa-onnx-core.a",
        "-force_load",
        "$libDir/libkaldi-decoder-core.a",
        "-force_load",
        "$libDir/libkaldi-native-fbank-core.a",
        "-force_load",
        "$libDir/libsherpa-onnx-kaldifst-core.a"
      ],
      dartBuildFiles: ['hook/build.dart'],
    );

    await cbuilder.run(
        buildConfig: config, buildOutput: output, logger: logger);

    if (config.targetOS == OS.macOS) {
      if (!config.dryRun) {
        final outDir = config.outputDirectory.toFilePath();
        Process.runSync('cp', ['-R', "$onnxLibDir/onnxruntime.framework", outDir]);
          // output.addAsset(NativeCodeAsset(
          //   package: config.packageName,
          //   name: "onnxruntime",
          //   linkMode: DynamicLoadingBundled(),
          //   os: config.targetOS,
          //   file: File("$onnxLibDir/onnxruntime.framework/onnxruntime").uri,
          //   architecture: config.targetArchitecture));
      }
    } else if (config.targetOS == OS.android) {
      if (!config.dryRun) {
        final archExtension = switch (config.targetArchitecture) {
          Architecture.arm => "arm-linux-androideabi",
          Architecture.arm64 => "aarch64-linux-android",
          Architecture.x64 => "x86_64-linux-android",
          Architecture.ia32 => "i686-linux-android",
          _ => throw FormatException('Invalid')
        };
        var ndkRoot = File(config.cCompiler.compiler!.path).parent.parent.path;
        var stlPath =
            File("$ndkRoot/sysroot/usr/lib/$archExtension/libc++_shared.so");
        // output.addAsset(NativeCodeAsset(
        //     package: "sherpa_onnx_dart",
        //     name: "libc++_shared.so",
        //     linkMode: DynamicLoadingBundled(),
        //     os: config.targetOS,
        //     file: stlPath.uri,
        //     architecture: config.targetArchitecture));
        for (final file in [
          "kaldi-decoder-core",
          "kaldi-native-fbank-core",
          "sherpa-onnx-c-api",
          "sherpa-onnx-fst",
          "sherpa-onnx-kaldifst-core",
          "sherpa-onnx-core"
        ]) {
          output.addAsset(NativeCodeAsset(
              package: "sherpa_onnx_dart",
              name: "lib${file}.so",
              linkMode: DynamicLoadingBundled(),
              os: config.targetOS,
              file: File("$libDir/lib${file}.so").uri,
              architecture: config.targetArchitecture));
        }

        
        output.addAsset(NativeCodeAsset(
            package: "sherpa_onnx_dart",
            name: "libonnxruntime.so",
            linkMode: DynamicLoadingBundled(),
            os: config.targetOS,
            file: File("$onnxLibDir/libonnxruntime.so").uri,
            architecture: config.targetArchitecture));
        output.addAsset(NativeCodeAsset(
            package: "sherpa_onnx_dart",
            name: "libcustom_op_library.so",
            linkMode: DynamicLoadingBundled(),
            os: config.targetOS,
            file: File("$onnxLibDir/libcustom_op_library.so").uri,
            architecture: config.targetArchitecture));
      }
    }
  });
}
