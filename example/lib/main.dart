import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:aubio_flutter/aubio_flutter.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'helpers/bufferutil.dart';

void main() {
  runApp(const AubioDemoApp());
}

class AubioDemoApp extends StatelessWidget {
  const AubioDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aubio Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioProcessingScreen(),
    );
  }
}

class AudioProcessingScreen extends StatefulWidget {
  const AudioProcessingScreen({super.key});

  @override
  State<AudioProcessingScreen> createState() => _AudioProcessingScreenState();
}

class _AudioProcessingScreenState extends State<AudioProcessingScreen> {
  final aubioProcessor = AubioProcessor();
  late FlutterAudioCapture flutterAudioCapture;
  late AudioPlayer _audioPlayer;
  bool audioPlayerLoaded = false;

  bool isRecording = false;
  bool isPlaying = false;
  bool saveRecording = false;
  bool enableHighPass = false;

  String pitchResult = "Not detected";
  String fftResult = "No data";
  String noteResult = "No note";
  String midiResult = "No MIDI";
  String centsResult = "No cents";

  List<double> audioBuffer = [];
  List<double> last5Seconds = [];
  List<double> filteredBuffer = [];
  double baseFrequency = 440.0;
  final int sampleRate = 16000;
  final int bufferSize = 512;
  final int maxBufferSize = 5 * 16000;

  @override
  void initState() {
    super.initState();
    flutterAudioCapture = FlutterAudioCapture();
    _audioPlayer = AudioPlayer();
    _initAudioCapture();
  }


  Future<void> _initAudioCapture() async {
    flutterAudioCapture.init();
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await flutterAudioCapture.stop();
      setState(() => isRecording = false);
      return;
    }

    if (!await _checkPermissions()) {
      setState(() => pitchResult = "Permission denied");
      return;
    }

    setState(() {
      isRecording = true;
      audioBuffer = [];
      last5Seconds = [];
      filteredBuffer = [];
    });

    try {
      await Future.delayed(Duration(milliseconds: 300));
      await flutterAudioCapture.start(
        listener,
        (error) => print("Error: $error"),
        sampleRate: sampleRate,
        bufferSize: bufferSize,
        waitForFirstDataOnAndroid: false,
        waitForFirstDataOnIOS: false,
      );
    } catch (e) {
      setState(() {
        isRecording = false;
        pitchResult = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> togglePlayback() async {
    if (filteredBuffer.isEmpty) return;

    if (isPlaying) {
      await _audioPlayer.stop();
      setState(() => isPlaying = false);
      return;
    }

    final pcmData = Int16List(filteredBuffer.length);
    for (int i = 0; i < filteredBuffer.length; i++) {
      pcmData[i] = (filteredBuffer[i] * 32767).clamp(-32768, 32767).toInt();
    }
    final bytes = Uint8List.view(pcmData.buffer);

    Uint8List uint8list = await BufferUtil.pcmToUint8List(bytes, sampleRate);
    Source byteSource = BytesSource(uint8list);
    _audioPlayer.setSource(byteSource);

    await _audioPlayer.play(byteSource);
    setState(() => isPlaying = true);
  }

  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void listener(dynamic data) async {
    final buffer = Float64List.fromList(data.cast<double>());
    final List<double> samples = buffer.toList();

    List<double> processedSamples = List.from(samples);

    if (enableHighPass) {
      final float32Buffer = Float32List.fromList(processedSamples);
      processedSamples = aubioProcessor.applyHighPassFilter(
        float32Buffer,
        sampleRate,
        1000.0,
      ).toList();
    }

    if (saveRecording) {
      last5Seconds.addAll(samples);
      filteredBuffer.addAll(processedSamples);

      if (last5Seconds.length > maxBufferSize) {
        last5Seconds = last5Seconds.sublist(last5Seconds.length - maxBufferSize);
        filteredBuffer = filteredBuffer.sublist(filteredBuffer.length - maxBufferSize);
      }
    }

    final Float32List float32Buffer = Float32List.fromList(processedSamples);
    final pitchValue = aubioProcessor.processPitchChunk(
      float32Buffer,
      method: 'yin',
      sampleRate: sampleRate,
    );

    final fftSize = 1024;
    final fft = aubioProcessor.processFFTChunk(float32Buffer, fftSize);
    final dominantFreq = aubioProcessor.findDominantFrequency(fft, 44100, fftSize);

    final midiNote = aubioProcessor.freqToMidi(pitchValue);
    final noteName = aubioProcessor.midiToNoteName(midiNote);
    final cents = aubioProcessor.freqToCents(pitchValue, baseFrequency);

    setState(() {
      pitchResult = "Pitch: ${pitchValue.toStringAsFixed(2)} Hz";
      fftResult = "FFT Dominant: ${dominantFreq.toStringAsFixed(2)} Hz";
      noteResult = "Note: $noteName";
      midiResult = "MIDI: ${midiNote.toStringAsFixed(2)}";
      centsResult = "Cents from A4: ${cents.toStringAsFixed(2)}";
      audioBuffer.addAll(processedSamples);
    });
  }

  @override
  void dispose() {
    flutterAudioCapture.stop();
    _audioPlayer.dispose();
    aubioProcessor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aubio Audio Processing')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: toggleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: Text(
                  isRecording ? 'STOP RECORDING' : 'START RECORDING',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),

              SwitchListTile(
                title: const Text('Save the last 5 seconds of recorded audio'),
                value: saveRecording,
                onChanged: (value) => setState(() => saveRecording = value),
              ),

              SwitchListTile(
                title: const Text('High-Pass Filter (1kHz)'),
                value: enableHighPass,
                onChanged: (value) => setState(() => enableHighPass = value),
              ),

              const SizedBox(height: 30),
              Text(pitchResult, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(fftResult, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(noteResult, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(midiResult, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(centsResult, style: const TextStyle(fontSize: 18)),

              if (filteredBuffer.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: togglePlayback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? Colors.orange : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  child: Text(
                    isPlaying ? 'STOP PLAYBACK' : 'PLAY FILTERED AUDIO',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 20),
                Text('Original Audio', style: const TextStyle(fontSize: 16)),
                Container(
                  height: 100,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: AudioWaveformPainter(last5Seconds),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Filtered Audio', style: const TextStyle(fontSize: 16)),
                Container(
                  height: 100,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: AudioWaveformPainter(filteredBuffer),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final List<double> samples;

  AudioWaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.width / samples.length;

    path.moveTo(0, size.height / 2);

    for (int i = 0; i < samples.length; i++) {
      final x = i * step;
      final y = size.height / 2 + samples[i] * size.height / 2;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

