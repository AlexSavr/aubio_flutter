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
  aubio_flutter:
    git:
      url: https://github.com/AlexSavr/aubio_flutter.git
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
* `silence`: (_Optional_) silence threshold of the audio signal. Defaults to **-30.0** db.
* `tolerance`: (_Optional_) tolerance threshold. Defaults to **0.5**. Min: 0.2 - Max: 0.9
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

### 3. `freqToMidiTuned`

### Description
Converts a frequency to a MIDI note number with custom tuning.

### Parameters
*   `freq`: The frequency (Hz) to convert.
*   `baseFreq`: The base frequency (Hz) for tuning (e.g., 440 for A4).

### Returns
The MIDI note number (e.g., 69 for A4 at 440 Hz).

### Example Usage
```dart
    final processor = AubioProcessor();
    double midiNote = processor.freqToMidiTuned(450.0, 440.0);
    print('MIDI Note: $midiNote'); // Output will be ~69.2 for 450Hz with A440 tuning
```

### 4. `midiToFreqTuned`

### Description
Converts a MIDI note number to a frequency with custom tuning.

### Parameters
*   `midi`: The MIDI note number (e.g., 69 for A4).
*   `baseFreq`: The base frequency (Hz) for tuning (e.g., 440 for A4).

### Returns
The frequency (Hz) of the note.

### Example Usage
```dart
    final processor = AubioProcessor();
    double frequency = processor.midiToFreqTuned(69.5, 432.0);
    print('Frequency: $frequency Hz'); // Output will be ~436.5 Hz for note 69.5 with A432 tuning
```

### 5. `freqToCents`

### Description
Converts a frequency to cents relative to a reference frequency.

### Parameters
*   `freq`: The input frequency (Hz).
*   `refFreq`: The reference frequency (Hz).

### Returns
The difference in cents (e.g., 0 if frequencies match).

### Example Usage
```dart
    final processor = AubioProcessor();
    double centsDiff = processor.freqToCents(445.0, 440.0);
    print('Cents difference: $centsDiff'); // Output will be ~19.6 cents
```

### 6. `midiToFreq`

### Description
Converts a MIDI note number to frequency (standard A440 tuning).

### Parameters
*   `midi`: The MIDI note number (e.g., 69 for A4).

### Returns
The frequency (Hz) of the note.

### Example Usage
```dart
    final processor = AubioProcessor();
    double frequency = processor.midiToFreq(60);
    print('Frequency: $frequency Hz'); // Output will be 261.63 Hz (middle C)
```

### 7. `midiToNoteName`

### Description
Converts a MIDI note number to a musical note name.

### Parameters
*   `midi`: The MIDI note number (e.g., 69 for A4).
*   `isFlatNames`: If \`true\`, uses flat names (e.g., "Bb4"); otherwise uses sharps (e.g., "A#4").

### Returns
The note name as a string (e.g., "A4").

### Example Usage
```dart
    final processor = AubioProcessor();
    String sharpName = processor.midiToNoteName(61);
    String flatName = processor.midiToNoteName(61, isFlatNames: true);
    print('Sharp name: $sharpName'); // Output: "C#4"
    print('Flat name: $flatName');   // Output: "Db4"
```

### 8. `freqToMidi`

### Description
Converts a frequency to a MIDI note number (standard A440 tuning).

### Parameters
*   `freq`: The frequency (Hz) to convert.

### Returns
The MIDI note number (e.g., 69 for 440 Hz).

### Example Usage
```dart
    final processor = AubioProcessor();
    double midiNote = processor.freqToMidi(880.0);
    print('MIDI Note: $midiNote'); // Output will be 81 (A5)
```

### 9. `findDominantFrequency`

### Description
Finds the dominant frequency from FFT results.

### Parameters
*   `fft`: FFT result containing real and imaginary parts.
*   `sampleRate`: Audio sample rate in Hz.
*   `fftSize`: Size of the FFT window used.

### Returns
Dominant frequency in Hz.

### Example Usage
```dart
    final processor = AubioProcessor();
    final samples = Float32List.fromList([/* audio samples here */]);
    
    // First get FFT results
    FFTResult fft = processor.processFFTChunk(samples, fftSize: 1024);
    
    // Then find dominant frequency
    double dominantFreq = processor.findDominantFrequency(fft, 44100, 1024);
    print('Dominant frequency: $dominantFreq Hz');
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
    * _silence_: silence threshold of the pitch detection object
    * _tolerance_: change _yin_ or _yinfft_ methods tolerance threshold
  
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
