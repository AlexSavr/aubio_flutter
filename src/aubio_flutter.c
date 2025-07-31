#include "aubio_flutter.h"

// =============================================
// Shared Buffer Management
// =============================================

FFI_PLUGIN_EXPORT SharedAudioBuffer* aubio_create_shared_buffer(uint32_t size) {
    SharedAudioBuffer* buf = malloc(sizeof(SharedAudioBuffer));
    if (!buf) return NULL;

    buf->data = calloc(size, sizeof(float));
    buf->size = size;
    return buf;
}

FFI_PLUGIN_EXPORT void aubio_release_shared_buffer(SharedAudioBuffer* buf) {
    if (!buf) return;
    free(buf->data);
    free(buf);
}

// =============================================
// Audio Processing Functions
// =============================================

FFI_PLUGIN_EXPORT float aubio_pitch_detect(
        SharedAudioBuffer* input,
        const char* method,
        uint_t samplerate,
        float silence,
        float tolerance
) {
    if (!input || !input->data) return 0.0f;

    uint_t buf_size = input->size;
    uint_t hop_size = buf_size / 2;

    fvec_t in_vec;
    in_vec.length = buf_size;
    in_vec.data = input->data;

    fvec_t out_vec;
    out_vec.length = 1;
    float pitch_result = 0.0f;
    out_vec.data = &pitch_result;

    aubio_pitch_t* pitch = new_aubio_pitch(method, buf_size, hop_size, samplerate);
    if (!pitch) {
        return 0.0f;
    }

    aubio_pitch_set_silence(pitch, silence);

    if (strcmp(method, "yin") == 0 || strcmp(method, "yinfft") == 0) {
        aubio_pitch_set_tolerance(pitch, tolerance);
    }

    aubio_pitch_do(pitch, &in_vec, &out_vec);
    del_aubio_pitch(pitch);

    return pitch_result;
}

FFI_PLUGIN_EXPORT void aubio_fft_transform(
        SharedAudioBuffer* input,
        SharedAudioBuffer* real_out,
        SharedAudioBuffer* imag_out,
        uint_t fft_size
) {
    if (!input || !real_out || !imag_out) return;
    if (!input->data || !real_out->data || !imag_out->data) return;

    fvec_t in_vec;
    in_vec.length = fft_size;
    in_vec.data = input->data;

    cvec_t spectrum;
    spectrum.length = fft_size / 2 + 1;
    spectrum.norm = real_out->data;
    spectrum.phas = imag_out->data;

    aubio_fft_t* fft = new_aubio_fft(fft_size);
    aubio_fft_do(fft, &in_vec, &spectrum);
    del_aubio_fft(fft);
}