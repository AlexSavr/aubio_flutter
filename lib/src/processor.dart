import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../aubio_flutter_bindings_generated.dart';

class FFTResult {
  final Float32List real;
  final Float32List imaginary;

  FFTResult({required this.real, required this.imaginary});
}

class AubioProcessor {
  static final _bindings = AubioFlutterBindings(_loadLibrary());
  Pointer<SharedAudioBuffer>? _inputBuffer;

  static DynamicLibrary _loadLibrary() {
    const String libName = 'aubio_flutter';
    if (Platform.isAndroid) {
      return DynamicLibrary.open('lib$libName.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.open('$libName.framework/$libName');
    }
    throw UnsupportedError('Platform not supported');
  }

  void _initBuffer(int size) {
    _inputBuffer ??= _bindings.aubio_create_shared_buffer(size);
  }

  void dispose() {
    if (_inputBuffer != null) {
      _bindings.aubio_release_shared_buffer(_inputBuffer!);
      _inputBuffer = null;
    }
  }

  /// Detects the pitch of an audio chunk using the specified method.
  ///
  /// - **samples**: A `Float32List` of audio samples to analyze.
  /// - **method**: The pitch detection algorithm (e.g., 'yin', 'yinfft'). Defaults to 'yin'.
  /// - **sampleRate**: The sample rate of the audio (Hz). Defaults to 44100.
  /// - **silence**: Silence threshold (dB). Defaults to -30.0.
  /// - **tolerance**: Detection tolerance. Defaults to 0.5.
  /// - **Returns**: The detected pitch in Hz.
  double processPitchChunk(Float32List samples, {String method = 'yin', int sampleRate = 44100, silence = -30.0, tolerance = 0.5}) {
    _initBuffer(samples.length);
    _fillSharedBuffer(_inputBuffer!, samples);

    final methodPtr = method.toNativeUtf8();
    final result = _bindings.aubio_pitch_detect(
        _inputBuffer!,
        methodPtr.cast<Char>(),
        sampleRate,
        silence,
        tolerance
    );
    calloc.free(methodPtr);

      return result;
  }

  /// Performs FFT on an audio chunk and returns the real/imaginary components.
  ///
  /// - **samples**: A `Float32List` of audio samples to transform.
  /// - **fftSize**: The size of the FFT window (must be power of 2).
  /// - **Returns**: An `FFTResult` containing real and imaginary parts.
  FFTResult processFFTChunk(Float32List samples, int fftSize) {
    _initBuffer(samples.length);
    final realBuffer = _bindings.aubio_create_shared_buffer(fftSize ~/ 2 + 1);
    final imagBuffer = _bindings.aubio_create_shared_buffer(fftSize ~/ 2 + 1);

    _fillSharedBuffer(_inputBuffer!, samples);

    _bindings.aubio_fft_transform(
      _inputBuffer!,
      realBuffer,
      imagBuffer,
      fftSize,
    );

    final result = FFTResult(
      real: _readSharedBuffer(realBuffer),
      imaginary: _readSharedBuffer(imagBuffer),
    );

    _bindings.aubio_release_shared_buffer(realBuffer);
    _bindings.aubio_release_shared_buffer(imagBuffer);

    return result;
  }

  /// Fills a shared buffer with audio samples.
  ///
  /// - **buffer**: A `Pointer<SharedAudioBuffer>` to the target buffer.
  /// - **samples**: A `Float32List` of audio data to copy.
  void _fillSharedBuffer(Pointer<SharedAudioBuffer> buffer, Float32List samples) {
    final dataPtr = buffer.ref.data;
    for (int i = 0; i < samples.length; i++) {
      dataPtr[i] = samples[i];
    }
  }

  /// Reads data from a shared buffer into a `Float32List`.
  ///
  /// - **buffer**: A `Pointer<SharedAudioBuffer>` to the source buffer.
  /// - **Returns**: A `Float32List` containing the copied data.
  Float32List _readSharedBuffer(Pointer<SharedAudioBuffer> buffer) {
    final result = Float32List(buffer.ref.size);
    final dataPtr = buffer.ref.data;
    for (int i = 0; i < result.length; i++) {
      result[i] = dataPtr[i];
    }
    return result;
  }

  /// Converts a frequency to a MIDI note number with custom tuning.
  ///
  /// - **freq**: The frequency (Hz) to convert.
  /// - **baseFreq**: The base frequency (Hz) for tuning (e.g., 440 for A4).
  /// - **Returns**: The MIDI note number (e.g., 69 for A4 at 440 Hz).
  double freqToMidiTuned(double freq, double baseFreq) {
    return _bindings.aubio_freq_to_midi_tuned(freq, baseFreq);
  }

  /// Converts a MIDI note number to a frequency with custom tuning.
  ///
  /// - **midi**: The MIDI note number (e.g., 69 for A4).
  /// - **baseFreq**: The base frequency (Hz) for tuning (e.g., 440 for A4).
  /// - **Returns**: The frequency (Hz) of the note.
  double midiToFreqTuned(double midi, double baseFreq) {
    return _bindings.aubio_midi_to_freq_tuned(midi, baseFreq);
  }

  /// Converts a frequency to cents relative to a reference frequency.
  ///
  /// - **freq**: The input frequency (Hz).
  /// - **refFreq**: The reference frequency (Hz).
  /// - **Returns**: The difference in cents (e.g., 0 if frequencies match).
  double freqToCents(double freq, double refFreq) {
    return _bindings.aubio_freq_to_cents(freq, refFreq);
  }

  /// Converts a MIDI note number to frequency (standard A440 tuning).
  ///
  /// - **midi**: The MIDI note number (e.g., 69 for A4).
  /// - **Returns**: The frequency (Hz) of the note.
  double midiToFreq(double midi) {
    return _bindings.aubio_midi_to_freq(midi);
  }

  /// Converts a MIDI note number to a musical note name.
  ///
  /// - **midi**: The MIDI note number (e.g., 69 for A4).
  /// - **isFlatNames**: If `true`, uses flat names (e.g., "Bb4"); otherwise uses sharps (e.g., "A#4").
  /// - **Returns**: The note name as a string (e.g., "A4").
  String midiToNoteName(double midi, {bool isFlatNames = false}) {
    const sharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    const flatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    final midiNote = midi.round();
    if (midiNote < 0 || midiNote > 127) {
      return "NaN";
    }

    final octave = (midiNote / 12).floor() - 1;
    final noteIndex = midiNote % 12;

    final names = isFlatNames ? flatNames : sharpNames;
    return '${names[noteIndex]}$octave';
  }

  /// Converts a frequency to a MIDI note number (standard A440 tuning).
  ///
  /// - **freq**: The frequency (Hz) to convert.
  /// - **Returns**: The MIDI note number (e.g., 69 for 440 Hz).
  double freqToMidi(double freq) {
    return _bindings.aubio_freq_to_midi(freq);
  }

  /// Finds the dominant frequency from FFT results.
  ///
  /// - [fft]: FFT result containing real and imaginary parts.
  /// - [sampleRate]: Audio sample rate in Hz.
  /// - [fftSize]: Size of the FFT window used.
  /// - Returns: Dominant frequency in Hz.
  double findDominantFrequency(FFTResult fft, int sampleRate, int fftSize) {
    double maxMagnitude = 0;
    int maxIndex = 0;

    for (int i = 0; i < fft.real.length; i++) {
      final magnitude = sqrt(pow(fft.real[i], 2) + pow(fft.imaginary[i], 2));
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
        maxIndex = i;
      }
    }

    return maxIndex * sampleRate / fftSize;
  }
}