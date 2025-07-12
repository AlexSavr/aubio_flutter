import 'dart:ffi';
import 'dart:io';
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

  static DynamicLibrary _loadLibrary() {
    const String libName = 'aubio_flutter';

    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$libName.framework/$libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$libName.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('$libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  Float32List pitchDetection(
      Float32List inputSamples, {
        String method = 'yin',
        double? lowpassCutoff,
        double? highpassCutoff,
        int sampleRate = 44100,
      }) {
    final inputBuffer = _bindings.aubio_create_shared_buffer(inputSamples.length);
    final outputBuffer = _bindings.aubio_create_shared_buffer(inputSamples.length);

    try {
      _fillSharedBuffer(inputBuffer, inputSamples);

      final methodPtr = method.toNativeUtf8().cast<Char>();
      _bindings.aubio_pitch_detect(
        inputBuffer,
        outputBuffer,
        methodPtr,
        sampleRate,
      );
      calloc.free(methodPtr.cast<Utf8>());

      if (lowpassCutoff != null) {
        _bindings.aubio_lowpass_filter(inputBuffer, lowpassCutoff, sampleRate);
      }

      if (highpassCutoff != null) {
        _bindings.aubio_highcut_filter(inputBuffer, highpassCutoff, sampleRate);
      }

      return _readSharedBuffer(inputBuffer);
    } finally {
      _bindings.aubio_release_shared_buffer(inputBuffer);
      _bindings.aubio_release_shared_buffer(outputBuffer);
    }
  }

  FFTResult processFFT(Float32List inputSamples, int fftSize) {
    final inputBuffer = _bindings.aubio_create_shared_buffer(inputSamples.length);
    final realBuffer = _bindings.aubio_create_shared_buffer(fftSize ~/ 2 + 1);
    final imagBuffer = _bindings.aubio_create_shared_buffer(fftSize ~/ 2 + 1);

    try {
      _fillSharedBuffer(inputBuffer, inputSamples);

      _bindings.aubio_fft_transform(
        inputBuffer,
        realBuffer,
        imagBuffer,
        fftSize,
      );

      return FFTResult(
        real: _readSharedBuffer(realBuffer),
        imaginary: _readSharedBuffer(imagBuffer),
      );
    } finally {
      _bindings.aubio_release_shared_buffer(inputBuffer);
      _bindings.aubio_release_shared_buffer(realBuffer);
      _bindings.aubio_release_shared_buffer(imagBuffer);
    }
  }

  void _fillSharedBuffer(Pointer<SharedAudioBuffer> buffer, Float32List samples) {
    final dataPtr = buffer.ref.data;
    for (int i = 0; i < samples.length; i++) {
      dataPtr[i] = samples[i];
    }
  }

  Float32List _readSharedBuffer(Pointer<SharedAudioBuffer> buffer) {
    final result = Float32List(buffer.ref.size);
    final dataPtr = buffer.ref.data;
    for (int i = 0; i < result.length; i++) {
      result[i] = dataPtr[i];
    }
    return result;
  }
}

AubioFlutterBindings initAubioBindings() {
  return AubioFlutterBindings(AubioProcessor._loadLibrary());
}