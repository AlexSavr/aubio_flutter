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
  String noteResult = "No note";
  String midiResult = "No MIDI";
  String centsResult = "No cents";
  List<double> audioSamples = [];
  double baseFrequency = 440.0;

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
      sampleRate: 16000,
    );

    final fftSize = 1024;
    final fft = aubioProcessor.processFFTChunk(float32Buffer, fftSize);
    final dominantFreq = aubioProcessor.findDominantFrequency(fft, 44100, fftSize);

    // Additional musical analysis
    final midiNote = aubioProcessor.freqToMidi(pitchValue);
    final noteName = aubioProcessor.midiToNoteName(midiNote);
    final cents = aubioProcessor.freqToCents(pitchValue, baseFrequency);

    setState(() {
      pitchResult = "Pitch: ${pitchValue.toStringAsFixed(2)} Hz";
      fftResult = "FFT Dominant: ${dominantFreq.toStringAsFixed(2)} Hz";
      noteResult = "Note: $noteName";
      midiResult = "MIDI: ${midiNote.toStringAsFixed(2)}";
      centsResult = "Cents from A4: ${cents.toStringAsFixed(2)}";
      audioSamples.addAll(samples);
    });
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
            const SizedBox(height: 8),
            Text(noteResult, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(midiResult, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(centsResult, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
