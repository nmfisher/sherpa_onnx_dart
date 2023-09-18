#ifndef _FLUTTER_SHERPA_ONNX_PLUGIN_C_API
#define _FLUTTER_SHERPA_ONNX_PLUGIN_C_API

#include <stdint.h>

typedef struct SherpaOnnxOnlineRecognizer SherpaOnnxOnlineRecognizer;

int flutter_sherpa_onnx_create(const char *tokens_path, const char *encoder_path, const char *decoder_path, const char *joiner_path);

void flutter_sherpa_onnx_destroy();

const char* flutter_sherpa_onnx_accept_waveform_s(const int16_t *data, int length);

#endif /* _FLUTTER_SHERPA_ONNX_PLUGIN_C_API */
