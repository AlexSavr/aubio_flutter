## 0.0.1

* Initial C-code ([aubio](https://github.com/aubio/aubio))
* added FFI Export for pitch_detect, lowpass_filter, highcut_filter, fft_transform
* Init shared buffer.

## 0.0.2
* added example
* removed lowpass_filter & highcut_filter (temporary)
* fixes in cmake

## 0.0.3
* added _silence_ param for pitch detect
* added _tolerance_ param for pitch detect

## 0.0.4
* added `aubio_freq_to_midi`, to get midi note from freq
* added `aubio_midi_to_freq`, to get freq from midi note
* added `aubio_freq_to_midi_tuned`, to get from base tune (eg. 440hz)
* added `aubio_midi_to_freq_tuned`, to get from base tune (eg. 440hz)
* added `aubio_freq_to_cents`, comparing two values and return cents (diff between the two values)