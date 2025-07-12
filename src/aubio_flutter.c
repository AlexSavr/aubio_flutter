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
        uint_t samplerate
) {
    if (!input) return 0.0f;

    uint_t buf_size = input->size;
    uint_t hop_size = buf_size / 2;

    aubio_pitch_t* pitch = new_aubio_pitch(method, buf_size, hop_size, samplerate);
    fvec_t in_vec = { input->data, buf_size };
    fvec_t out_vec = { NULL, 1 };

    float pitch_result = 0.0f;
    out_vec.data = &pitch_result;

    aubio_pitch_do(pitch, &in_vec, &out_vec);
    del_aubio_pitch(pitch);

    return pitch_result;
}

FFI_PLUGIN_EXPORT void aubio_lowpass_filter(
        SharedAudioBuffer* buffer,
        smpl_t cutoff_freq,
        uint_t samplerate
) {
    if (!buffer) return;

    aubio_filter_t* filter = new_aubio_filter_lowpass(cutoff_freq, samplerate);
    fvec_t vec = { buffer->data, buffer->size };

    aubio_filter_do(filter, &vec);
    del_aubio_filter(filter);
}

FFI_PLUGIN_EXPORT void aubio_highcut_filter(
        SharedAudioBuffer* buffer,
        smpl_t cutoff_freq,
        uint_t samplerate
) {
    if (!buffer) return;

    aubio_filter_t* filter = new_aubio_filter_highpass(cutoff_freq, samplerate);
    fvec_t vec = { buffer->data, buffer->size };

    aubio_filter_do(filter, &vec);
    del_aubio_filter(filter);
}

FFI_PLUGIN_EXPORT void aubio_fft_transform(
        SharedAudioBuffer* input,
        SharedAudioBuffer* real_out,
        SharedAudioBuffer* imag_out,
        uint_t fft_size
) {
    if (!input || !real_out || !imag_out) return;
    if (real_out->size != fft_size/2+1 || imag_out->size != fft_size/2+1) return;

    aubio_fft_t* fft = new_aubio_fft(fft_size);
    fvec_t in_vec = { input->data, fft_size };
    cvec_t spectrum = { real_out->data, imag_out->data, fft_size };

    aubio_fft_do(fft, &in_vec, &spectrum);
    del_aubio_fft(fft);
}