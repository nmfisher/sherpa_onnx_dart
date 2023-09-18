# flutter_sherpa_onnx

A new flutter plugin project.

# Generating FFI bindings

dart run ffigen 

# Kaldi

Kaldi kaldi_vosk / OpenFST openfst_vosk

Linux (MKL)
CXXFLAGS="-fPIC" ./configure --prefix=$(pwd)/build/x86_64_linux/ --enable-static --enable-far --enable-ngram-fsts --enable-lookahead-fsts
CXXFLAGS="-fPIC" ./configure --fst-root=/home/hydroxide/projects/openfst_vosk/build/x86_64_linux --use-cuda=no --static-fst --static

iOS

CXX=clang++ CXXFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/ -target aarch64-apple-ios -stdlib=libc++ --std=c++14 -Wl,-arch -Wl,arm64" ./configure  --enable-static --enable-far --enable-ngram-fsts --enable-lookahead-fsts --prefix=$(realpath ./build/aarch64_ios)

CC=clang CXX=clang++ LDFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/ -target aarch64-apple-ios -stdlib=libc++" CXXFLAGS="-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/ -target aarch64-apple-ios -stdlib=libc++" ./configure   --static --static-fst --fst-root=$(grealpath ../tools/openfst-1.7.3/build/aarch64_ios)

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

The plugin project was generated without specifying the `--platforms` flag, no platforms are currently supported.
To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.
# flutter_sherpa_onnx
