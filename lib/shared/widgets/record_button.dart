// record_button.dart
import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onStartRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;
  final VoidCallback onStopRecording;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.onStartRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    // Change icon and action based on the current state.
    IconData icon;
    VoidCallback onPressed;
    if (!isRecording && !isPaused) {
      icon = Icons.fiber_manual_record;
      onPressed = onStartRecording;
    } else if (isRecording && !isPaused) {
      icon = Icons.pause;
      onPressed = onPauseRecording;
    } else if (isRecording && isPaused) {
      icon = Icons.play_arrow;
      onPressed = onResumeRecording;
    } else {
      icon = Icons.fiber_manual_record;
      onPressed = onStartRecording;
    }
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.red,
      child: Icon(icon, size: 32),
    );
  }
}
