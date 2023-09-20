cmake_minimum_required(VERSION 3.10)  

set(ANDROID_STL c++_shared)

file(TO_NATIVE_PATH "/" s)
string(REPLACE "flutter_sherpa_onnx${s}intermediates${s}cmake" "flutter_onnx${s}intermediates${s}merged_jni_libs" FLUTTER_ONNX_JNI_DIR ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
string(REPLACE "obj" "out" FLUTTER_ONNX_JNI_DIR ${FLUTTER_ONNX_JNI_DIR})

include_directories(../ios/include)
link_directories(src/main/jniLibs/${ANDROID_ABI})
link_directories(${FLUTTER_ONNX_JNI_DIR})

add_library( 
    flutter_sherpa_onnx_plugin
    SHARED
    src/main/cpp/dummy.cpp
)

target_link_libraries(flutter_sherpa_onnx_plugin -landroid -llog -lc++ -lsherpa-onnx-core -lkaldi-native-fbank-core -lsherpa-onnx-c-api)
