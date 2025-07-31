#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include "aubio.h"

#define FFI_PLUGIN_EXPORT

#ifndef SHARED_BUFFER_H
#define SHARED_BUFFER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float* data;
    uint32_t size;
} SharedAudioBuffer;

FFI_PLUGIN_EXPORT SharedAudioBuffer* aubio_create_shared_buffer(uint32_t size);
FFI_PLUGIN_EXPORT void aubio_release_shared_buffer(SharedAudioBuffer* buf);

FFI_PLUGIN_EXPORT float aubio_pitch_detect(
        SharedAudioBuffer* input,
        const char* method,
        uint_t samplerate,
        float silence,
        float tolerance
);

FFI_PLUGIN_EXPORT void aubio_fft_transform(
        SharedAudioBuffer* input,
        SharedAudioBuffer* real_out,
        SharedAudioBuffer* imag_out,
        uint_t fft_size
);


#ifdef __cplusplus
}
#endif

#endif