#include "FlutterSherpaOnnxPluginCApi.h"

#include <sys/types.h>
#include <sys/stat.h>

#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sherpa-onnx/c-api/c-api.h"

#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))

static SherpaOnnxOnlineRecognizer* _recognizer;
static SherpaOnnxOnlineStream* _stream;

FLUTTER_PLUGIN_EXPORT int flutter_sherpa_onnx_create(const char *tokens_path, const char *encoder_path, const char *decoder_path, const char *joiner_path)
{

   if(_recognizer || _stream) {
      // FAIL
   }

   SherpaOnnxOnlineRecognizerConfig config;

   config.model_config.debug = 0;
   config.model_config.num_threads = 1;
   config.model_config.provider = "cpu";

   config.decoding_method = "greedy_search";

   config.max_active_paths = 4;

   config.feat_config.sample_rate = 16000;
   config.feat_config.feature_dim = 80;

   config.enable_endpoint = 1;
   config.rule1_min_trailing_silence = 2.4;
   config.rule2_min_trailing_silence = 1.2;
   config.rule3_min_utterance_length = 300;

   char identifier;
   const char *value;
   config.model_config.tokens = tokens_path;
   config.model_config.transducer.encoder = encoder_path;        
   config.model_config.transducer.decoder = decoder_path;
   config.model_config.transducer.joiner = joiner_path;
   config.model_config.num_threads = atoi(value);
   config.model_config.provider = value;
   config.decoding_method = value;
   config.hotwords_file = value;
   config.hotwords_score = atof(value);

   _recognizer = CreateOnlineRecognizer(&config);
   _stream = CreateOnlineStream(_recognizer);

   SherpaOnnxDisplay *display = CreateDisplay(50);
   int32_t segment_id = 0;

   return 1;

}

FLUTTER_PLUGIN_EXPORT void flutter_sherpa_onnx_destroy()
{
   DestroyOnlineStream(_stream);
   DestroyOnlineRecognizer(_recognizer);
}

FLUTTER_PLUGIN_EXPORT const char* flutter_sherpa_onnx_accept_waveform_s(const int16_t *data, int length)
{

   float samples[length];

   for(int i =0 ; i < length; i++) {
      samples[i] = data[i] / 32768.0f;
   }

   AcceptWaveform(_stream, 16000, samples, length);
   while (IsOnlineStreamReady(_recognizer, _stream)) {
      DecodeOnlineStream(_recognizer, _stream);
   }

   const SherpaOnnxOnlineRecognizerResult *r =
      GetOnlineStreamResult(_recognizer, _stream);

   
   // if (IsEndpoint(recognizer, _stream)) {
   //    Reset(recognizer, _stream);
   // }

   DestroyOnlineRecognizerResult(r);
   return r->json;
}        



