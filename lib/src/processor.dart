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

  double processPitchChunk(Float32List samples, {String method = 'yin', int sampleRate = 44100}) {
    _initBuffer(samples.length);
    _fillSharedBuffer(_inputBuffer!, samples);

    final methodPtr = method.toNativeUtf8();
    final result = _bindings.aubio_pitch_detect(
      _inputBuffer!,
      methodPtr.cast<Char>(),
      sampleRate,
    );
    calloc.free(methodPtr);

    return result;
  }

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