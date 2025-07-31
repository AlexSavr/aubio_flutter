# aubio_flutter

Flutter plugin for audio processing using [aubio](https://github.com/aubio/aubio).

## Project structure

Structure:

* `src`: Contains the native source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

## Installation
Add the `aubio_flutter` package to your `pubspec.yaml` file:
```yaml
dependencies:
  aubio_flutter: ^0.0.2
```
Then run `flutter pub get` to install the package.

## Methods in `AubioProcessor`

### 1. `processPitchChunk`
### Description
Detects the pitch (fundamental frequency) of an audio chunk using various pitch detection algorithms.

### Parameters
* `samples`: A `Float32List` containing the audio samples.
* `method`: (_Optional_) The pitch detection algorithm to use. Defaults to `'yin'`. [Methods List](https://aubio.org/doc/latest/pitch_8h.html)
* `sampleRate`: (_Optional_) The sample rate of the audio signal. Defaults to **44100**.
### Returns
* A `double` representing the detected pitch in Hertz (Hz). If no pitch is detected, the value will be **0.0**.
### Example Usage
```dart
final processor = AubioProcessor();
final samples = Float32List.fromList([/* audio samples here */]);

double pitch = processor.processPitchChunk(
  samples,
  method: 'yin',
  sampleRate: 44100,
);

print('Detected Pitch: $pitch Hz');
```

### 2. `processFFTChunk`

### Description
Performs a Fast Fourier Transform (FFT) on an audio chunk to analyze its frequency spectrum.

### Parameters
* `samples`: A `Float32List` containing the audio samples.
* `fftSize`: The size of the FFT window. Must be a power of 2 (_e.g., 512, 1024_).

### Returns
* An `FFTResult` object containing two `Float32List` arrays:
  * `real`: The real part of the FFT result.
  * `imaginary`: The imaginary part of the FFT result.

### Example Usage
```dart
final processor = AubioProcessor();
final samples = Float32List.fromList([/* audio samples here */]);

FFTResult fft = processor.processFFTChunk(samples, fftSize: 1024);

print('Real Part: ${fft.real}');
print('Imaginary Part: ${fft.imaginary}');
```
 ⠀
 ⠀
__________

 ⠀
## Functions from aubio-c in Flutter with FFI:
* ```c++
  aubio_pitch_detect(input, method, samplerate)
  ```
    Used for getting pitch of sample
    * _input_: your samples
    * _method_: pitch detection method. [Methods List](https://aubio.org/doc/latest/pitch_8h.html)
    * _samplerate_: your sample rate of input
  
 ⠀
* ```c++
  aubio_fft_transform(input, real_out, imag_out, fft_size)
  ```
  Used for getting _FFT Dominant Hz_ in sample
    * _input_: your samples
    * _real_out_: real buffer (_result of ```aubio_create_shared_buffer```_)
    * _imag_out_: imaginary buffer (_result of ```aubio_create_shared_buffer```_)
    * _fft_size_: your fft size

 ⠀
* ```c++
  aubio_create_shared_buffer(size)
   ```
   Used for creating shared buffer between flutter & C-code
 
 ⠀
* ```c++
  aubio_release_shared_buffer(buffer)
   ```
   Used for releasing created shared buffer
