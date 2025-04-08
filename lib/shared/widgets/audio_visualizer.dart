// audio_visualizer.dart
import 'package:flutter/material.dart';

class AudioVisualizer extends StatelessWidget {
  final bool isRecording;
  final double amplitude;

  const AudioVisualizer({
    super.key,
    required this.isRecording,
    required this.amplitude,
  });

  @override
  Widget build(BuildContext context) {
    // For simplicity, we display a vertical bar scaled by the amplitude.
    return Container(
      width: 50,
      height: 200,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: isRecording ? (amplitude * 5).clamp(0, 200) : 0,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
