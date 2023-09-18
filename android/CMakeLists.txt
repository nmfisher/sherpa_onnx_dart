cmake_minimum_required(VERSION 3.10)  

set(ANDROID_STL c++_shared)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")


string(REPLACE "flutter_sherpa_onnx\\intermediates\\cmake" "flutter_kaldi_libs\\intermediates\\merged_jni_libs" JNI_DIR ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
string(REPLACE "obj" "out" JNI_DIR ${JNI_DIR})

include_directories(../ios/include)
include_directories(../ios/include/kaldi)
include_directories(../ios/include/dart)
link_directories(src/main/jniLibs/${ANDROID_ABI})
link_directories(${JNI_DIR})
add_library( 
            flutter_sherpa_onnx_plugin
            SHARED
            ../ios/Classes/model.cc
            ../ios/Classes/recognizer.cc
            ../ios/Classes/custom_api.cc
            ../ios/Classes/spk_model.cc
            ../ios/Classes/language_model.cc
            ../ios/Classes/dart_api_dl.c
        )

 target_link_libraries(flutter_sherpa_onnx_plugin -landroid -llog -lc++ -l:kaldi-fstext.a -l:kaldi-chain.a -l:kaldi-nnet3.a -l:kaldi-online2.a -l:kaldi-feat.a -l:kaldi-ivector.a -l:kaldi-rnnlm.a -l:kaldi-lm.a -l:kaldi-decoder.a -l:kaldi-lat.a 
 -l:kaldi-hmm.a -l:kaldi-transform.a -l:kaldi-gmm.a -l:kaldi-tree.a -l:kaldi-cudamatrix.a -l:kaldi-matrix.a -l:kaldi-util.a -l:kaldi-base.a -l:liblapack.a -l:libopenblas.a  -l:libblas.a -l:libf2c.a  -l:libfst.a -l:ngram-fst.a -l:libfstngram.a  -l:olabel_lookahead-fst.a -l:libfstlookahead.a)
