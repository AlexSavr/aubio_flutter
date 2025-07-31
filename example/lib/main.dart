import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aubio_flutter/aubio_flutter.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

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

  bool isRecording = false;
  String pitchResult = "Not detected";
  String fftResult = "No data";
  List<double> audioSamples = [];

  @override
  void initState() {
    super.initState();
    flutterAudioCapture = FlutterAudioCapture();
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
      audioSamples = [];
    });

    try {
      await Future.delayed(Duration(milliseconds: 300));
      await flutterAudioCapture.start(
        listener,
            (error) => print("Error: $error"),
        sampleRate: 16000,
        bufferSize: 512,
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

  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void listener(dynamic data) async {
    final buffer = Float64List.fromList(data.cast<double>());
    final List<double> samples = buffer.toList();

    final Float32List float32Buffer = Float32List(samples.length);

    for (int i = 0; i < samples.length; i++) {
      float32Buffer[i] = samples[i];
    }

    final pitchValue = aubioProcessor.processPitchChunk(
      float32Buffer,
      method: 'yin',
      sampleRate: 44100,
    );

    final fftSize = 1024;
    final fft = aubioProcessor.processFFTChunk(float32Buffer, fftSize);
    final dominantFreq = _findDominantFrequency(fft, 44100, fftSize);

    setState(() {
      pitchResult = "Pitch: ${pitchValue.toStringAsFixed(2)} Hz";
      fftResult = "FFT Dominant: ${dominantFreq.toStringAsFixed(2)} Hz";
      audioSamples.addAll(samples);
    });
  }

  double _findDominantFrequency(FFTResult fft, int sampleRate, int fftSize) {
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

  @override
  void dispose() {
    flutterAudioCapture.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aubio Audio Processing')),
      body: Center(
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
            const SizedBox(height: 30),
            Text(pitchResult, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(fftResult, style: const TextStyle(fontSize: 18)),
          ],
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
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dx = size.width / samples.length;

    path.moveTo(0, size.height / 2);

    for (int i = 0; i < samples.length; i++) {
      final x = i * dx;
      final y = size.height / 2 - samples[i] * size.height / 2;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}