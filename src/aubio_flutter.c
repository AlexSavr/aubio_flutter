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

FFI_PLUGIN_EXPORT const char* aubio_midi_to_note_name(float midi, bool is_flat_names) {
    static const char* sharp_names[] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    static const char* flat_names[] = {"C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"};

    int midi_note = (int)roundf(midi);
    if (midi_note < 0 || midi_note > 127) {
        return "NaN";
    }

    int octave = (midi_note / 12) - 1;
    int note_index = midi_note % 12;

    const char** names = is_flat_names ? flat_names : sharp_names;

    static char result[8];
    snprintf(result, sizeof(result), "%s%d", names[note_index], octave);

    return result;
}