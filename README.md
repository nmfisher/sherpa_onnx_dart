# flutter_sherpa_onnx
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


# warning
this lib currently uses sherpa-onnx 1.8.9 and ONNXRuntime 1.16.2 but all libs are not updated yet, this should only work for Android & iOS arm64, not the others OS


# setup
flutter_sherpa_onnx and flutter_ffi_asset_helper repositories give a starting point.

Please note :

1) make sure to run `git lfs pull` when you clone because the sherpa-onnx binaries libs are commited within the actual repository
2) you will need to compile your own version of ONNXRuntime and place in the appropriate folders (you'll see some hardcoded paths/symbolic links in the Android src/main/jniLibs folder and the ios/flutter_sherpa_onnx.podspec, you may need to change these)

- clone : https://github.com/microsoft/onnxruntime

- for ios, I see these files 
- ...flutter_sherpa_onnx/ios/lib/ 

- for android, I see the alias...
android/src/main/jniLibs

./build.sh --android --android_sdk_path <android sdk path> --android_ndk_path <android ndk path> --android_abi <android abi, e.g., arm64-v8a (default) or armeabi-v7a> --android_api <android api level, e.g., 27 (default)>

./build.sh --config <Release|Debug|RelWithDebInfo|MinSizeRel> --use_xcode \
           --ios --ios_sysroot iphoneos --osx_arch arm64 --apple_deploy_target <minimal iOS version>


- check out the example app (which uses a Chinese model) and try and get that running as-is first, before trying to incorporate it into your own project.

There's zero documentation but here is how to :

1) create an instance of FlutterSherpaOnnxFFI 
2) call createRecognizer with the sample rate, chunk length (which is basically how much audio you want to process at any one time, usually 0.1 is fine (100ms)) and the asset paths to your sherpa-onnx files
3) call createStream with an optional list of phrases to use as hotwords (null if you don't want to use hotwords)
4) in your app, choose whatever microphone plugin then pass the microphone data as Uint8List (must be int16 PCM at the sample rat you specified earlier) to acceptWaveform
5) listen to the result stream to get the ASR results

Note : 

1) the actual model runs on a background isolate which is why everything is asynchronous (this was intentional to avoid blocking the flutter UI thread when there was heavy decoding going on)
