// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `src/aubio_flutter.h`.
///
/// Regenerate bindings with `dart run ffigen --config ffigen.yaml`.
///
class AubioFlutterBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  AubioFlutterBindings(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  AubioFlutterBindings.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  ffi.Pointer<SharedAudioBuffer> aubio_create_shared_buffer(int size) {
    return _aubio_create_shared_buffer(size);
  }

  late final _aubio_create_shared_bufferPtr =
      _lookup<
        ffi.NativeFunction<ffi.Pointer<SharedAudioBuffer> Function(ffi.Uint32)>
      >('aubio_create_shared_buffer');
  late final _aubio_create_shared_buffer = _aubio_create_shared_bufferPtr
      .asFunction<ffi.Pointer<SharedAudioBuffer> Function(int)>();

  void aubio_release_shared_buffer(ffi.Pointer<SharedAudioBuffer> buf) {
    return _aubio_release_shared_buffer(buf);
  }

  late final _aubio_release_shared_bufferPtr =
      _lookup<
        ffi.NativeFunction<ffi.Void Function(ffi.Pointer<SharedAudioBuffer>)>
      >('aubio_release_shared_buffer');
  late final _aubio_release_shared_buffer = _aubio_release_shared_bufferPtr
      .asFunction<void Function(ffi.Pointer<SharedAudioBuffer>)>();

  double aubio_pitch_detect(
    ffi.Pointer<SharedAudioBuffer> input,
    ffi.Pointer<ffi.Char> method,
    int samplerate,
    double silence,
    double tolerance,
  ) {
    return _aubio_pitch_detect(input, method, samplerate, silence, tolerance);
  }

  late final _aubio_pitch_detectPtr =
      _lookup<
        ffi.NativeFunction<
          ffi.Float Function(
            ffi.Pointer<SharedAudioBuffer>,
            ffi.Pointer<ffi.Char>,
            uint_t,
            ffi.Float,
            ffi.Float,
          )
        >
      >('aubio_pitch_detect');
  late final _aubio_pitch_detect = _aubio_pitch_detectPtr
      .asFunction<
        double Function(
          ffi.Pointer<SharedAudioBuffer>,
          ffi.Pointer<ffi.Char>,
          int,
          double,
          double,
        )
      >();

  void aubio_fft_transform(
    ffi.Pointer<SharedAudioBuffer> input,
    ffi.Pointer<SharedAudioBuffer> real_out,
    ffi.Pointer<SharedAudioBuffer> imag_out,
    int fft_size,
  ) {
    return _aubio_fft_transform(input, real_out, imag_out, fft_size);
  }

  late final _aubio_fft_transformPtr =
      _lookup<
        ffi.NativeFunction<
          ffi.Void Function(
            ffi.Pointer<SharedAudioBuffer>,
            ffi.Pointer<SharedAudioBuffer>,
            ffi.Pointer<SharedAudioBuffer>,
            uint_t,
          )
        >
      >('aubio_fft_transform');
  late final _aubio_fft_transform = _aubio_fft_transformPtr
      .asFunction<
        void Function(
          ffi.Pointer<SharedAudioBuffer>,
          ffi.Pointer<SharedAudioBuffer>,
          ffi.Pointer<SharedAudioBuffer>,
          int,
        )
      >();

  double aubio_freq_to_midi(double freq) {
    return _aubio_freq_to_midi(freq);
  }

  late final _aubio_freq_to_midiPtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Float)>>(
        'aubio_freq_to_midi',
      );
  late final _aubio_freq_to_midi = _aubio_freq_to_midiPtr
      .asFunction<double Function(double)>();

  double aubio_midi_to_freq(double midi) {
    return _aubio_midi_to_freq(midi);
  }

  late final _aubio_midi_to_freqPtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Float)>>(
        'aubio_midi_to_freq',
      );
  late final _aubio_midi_to_freq = _aubio_midi_to_freqPtr
      .asFunction<double Function(double)>();

  double aubio_freq_to_cents(double freq, double ref_freq) {
    return _aubio_freq_to_cents(freq, ref_freq);
  }

  late final _aubio_freq_to_centsPtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Float, ffi.Float)>>(
        'aubio_freq_to_cents',
      );
  late final _aubio_freq_to_cents = _aubio_freq_to_centsPtr
      .asFunction<double Function(double, double)>();

  double aubio_midi_to_freq_tuned(double midi, double base_freq) {
    return _aubio_midi_to_freq_tuned(midi, base_freq);
  }

  late final _aubio_midi_to_freq_tunedPtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Float, ffi.Float)>>(
        'aubio_midi_to_freq_tuned',
      );
  late final _aubio_midi_to_freq_tuned = _aubio_midi_to_freq_tunedPtr
      .asFunction<double Function(double, double)>();

  double aubio_freq_to_midi_tuned(double freq, double base_freq) {
    return _aubio_freq_to_midi_tuned(freq, base_freq);
  }

  late final _aubio_freq_to_midi_tunedPtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Float, ffi.Float)>>(
        'aubio_freq_to_midi_tuned',
      );
  late final _aubio_freq_to_midi_tuned = _aubio_freq_to_midi_tunedPtr
      .asFunction<double Function(double, double)>();
}

final class SharedAudioBuffer extends ffi.Struct {
  external ffi.Pointer<ffi.Float> data;

  @ffi.Uint32()
  external int size;
}

/// unsigned integer
typedef uint_t = ffi.UnsignedInt;
typedef Dartuint_t = int;
