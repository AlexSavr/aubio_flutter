#include "aubio_flutter.h"

// =============================================
// Utils
// =============================================
static void create_filter_coeffs(fmat_t* coeffs, uint_t win_s, uint_t samplerate, float cutoff_freq, bool is_highpass) {
    fvec_t* freqs = new_fvec(2);
    if (is_highpass) {
        fvec_set_sample(freqs, cutoff_freq, 0);
        fvec_set_sample(freqs, samplerate/2, 1);
    } else {
        fvec_set_sample(freqs, 0, 0);
        fvec_set_sample(freqs, cutoff_freq, 1);
    }

    aubio_filterbank_t* fb = new_aubio_filterbank(1, win_s);
    aubio_filterbank_set_triangle_bands(fb, freqs, samplerate);

    fmat_t* fb_coeffs = aubio_filterbank_get_coeffs(fb);
    fmat_copy(fb_coeffs, coeffs);

    del_aubio_filterbank(fb);
    del_fvec(freqs);
}

static void apply_filter_to_spectrum(
        cvec_t* spectrum,
        uint_t fft_size,
        uint_t samplerate,
        float cutoff_freq,
        int is_highpass)
{
    fmat_t* coeffs = new_fmat(1, fft_size/2 + 1);
    if (!coeffs) return;

    create_filter_coeffs(coeffs, fft_size, samplerate, cutoff_freq, is_highpass);

    for (uint_t i = 0; i < spectrum->length; i++) {
        spectrum->norm[i] *= coeffs->data[0][i];
    }

    del_fmat(coeffs);
}

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
        float tolerance,
        float highpass_cutoff,
        float lowpass_cutoff)
{
    if (!input || !input->data || input->size == 0) {
        fprintf(stderr, "Invalid input buffer");
        return 0.0f;
    }

    const uint_t buf_size = input->size;
    const uint_t hop_size = buf_size / 2;

    uint_t fft_size = buf_size;
    if ((fft_size & (fft_size - 1)) != 0) { // Проверка на степень двойки
        fft_size = 1 << (int)(log2(fft_size) + 1); // Ближайшая большая степень двойки
        fprintf(stderr, "Adjusting FFT size (nearest power of two)");
    }

    fvec_t in_vec = {.length = buf_size, .data = input->data};
    fvec_t out_vec = {.length = 1, .data = &(float){0.0f}};

    aubio_fft_t* fft = new_aubio_fft(fft_size);
    if (!fft) {
        fprintf(stderr, "Failed to create FFT of size");
        return 0.0f;
    }

    if (highpass_cutoff > 0 || lowpass_cutoff > 0) {
        cvec_t* spectrum = new_cvec(fft_size);
        if (!spectrum) {
            del_aubio_fft(fft);
            fprintf(stderr, "Failed to create spectrum buffer");

            return 0.0f;
        }

        if (aubio_fft_do(fft, &in_vec, spectrum) != 0) {
            del_cvec(spectrum);
            del_aubio_fft(fft);
            fprintf(stderr, "FFT computation failed");

            return 0.0f;
        }

        if (highpass_cutoff > 0 && highpass_cutoff < samplerate/2) {
            apply_filter_to_spectrum(spectrum, fft_size, samplerate, highpass_cutoff, 1);
        }
        if (lowpass_cutoff > 0 && lowpass_cutoff < samplerate/2) {
            apply_filter_to_spectrum(spectrum, fft_size, samplerate, lowpass_cutoff, 0);
        }

        if (aubio_fft_rdo(fft, spectrum, &in_vec) != 0) {
            fprintf(stderr, "Inverse FFT computation failed");
        }
        del_cvec(spectrum);
    }

    aubio_pitch_t* pitch = new_aubio_pitch(method, buf_size, hop_size, samplerate);
    if (!pitch) {
        del_aubio_fft(fft);
        fprintf(stderr, "Failed to create pitch detector");
        return 0.0f;
    }

    aubio_pitch_set_silence(pitch, silence);
    if (strcmp(method, "yin") == 0 || strcmp(method, "yinfft") == 0) {
        aubio_pitch_set_tolerance(pitch, tolerance);
    }

    aubio_pitch_do(pitch, &in_vec, &out_vec);
    float result = out_vec.data[0];

    del_aubio_pitch(pitch);
    del_aubio_fft(fft);

    return result;
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

// =============================================
// Musical Conversion Functions
// =============================================

FFI_PLUGIN_EXPORT float aubio_freq_to_midi(float freq) {
    return aubio_freqtomidi(freq);
}

FFI_PLUGIN_EXPORT float aubio_midi_to_freq(float midi) {
    return aubio_miditofreq(midi);
}

FFI_PLUGIN_EXPORT float aubio_freq_to_midi_tuned(float freq, float base_freq) {
    return 69.0f + 12.0f * log2f(freq / base_freq);
}

FFI_PLUGIN_EXPORT float aubio_midi_to_freq_tuned(float midi, float base_freq) {
    if(!base_freq) {
        base_freq = 440.0;
    }
    return base_freq * powf(2.0f, (midi - 69.0f) / 12.0f);
}

FFI_PLUGIN_EXPORT float aubio_freq_to_cents(float freq, float ref_freq) {
    if (freq <= 0 || ref_freq <= 0) return 0;
    return 1200.0f * log2f(freq / ref_freq);
}


FFI_PLUGIN_EXPORT void aubio_high_pass_filter(
        SharedAudioBuffer* input,
        SharedAudioBuffer* output,
        uint_t samplerate,
        float cutoff_freq
) {
    if (!input || !output || input->size != output->size) return;
    if (!input->data || !output->data) return;
    if (cutoff_freq <= 0 || cutoff_freq >= samplerate/2) return;

    uint_t win_s = input->size;
    if ((win_s & (win_s - 1)) != 0) {
        fprintf(stderr, "Buffer size must be power of two, got %d\n", win_s);
        return;
    }

    aubio_fft_t* fft = new_aubio_fft(win_s);
    if (!fft) {
        fprintf(stderr, "Failed to create FFT object\n");
        return;
    }

    cvec_t* fftgrain = new_cvec(win_s);
    if (!fftgrain) {
        fprintf(stderr, "Failed to create FFT grain\n");
        del_aubio_fft(fft);
        return;
    }

    fmat_t* coeffs = new_fmat(1, win_s/2 + 1);
    if (!coeffs) {
        fprintf(stderr, "Failed to create filter coefficients\n");
        del_cvec(fftgrain);
        del_aubio_fft(fft);
        return;
    }

    create_filter_coeffs(coeffs, win_s, samplerate, cutoff_freq, true);

    fvec_t in_vec, out_vec;
    in_vec.length = win_s;
    in_vec.data = input->data;
    out_vec.length = win_s;
    out_vec.data = output->data;

    aubio_fft_do(fft, &in_vec, fftgrain);

    for (uint_t i = 0; i < fftgrain->length; i++) {
        fftgrain->norm[i] *= coeffs->data[0][i];
    }

    aubio_fft_rdo(fft, fftgrain, &out_vec);

    del_fmat(coeffs);
    del_cvec(fftgrain);
    del_aubio_fft(fft);
}