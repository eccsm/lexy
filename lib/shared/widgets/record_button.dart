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
    return GestureDetector(
      onTap: () {
        if (!isRecording) {
          onStartRecording();
        } else if (isPaused) {
          onResumeRecording();
        } else {
          onPauseRecording();
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _getButtonColor(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isRecording && !isPaused ? 24 : 36,
            height: isRecording && !isPaused ? 24 : 36,
            decoration: BoxDecoration(
              color: isRecording ? Colors.white : Colors.red,
              borderRadius: BorderRadius.circular(
                isPaused ? 4 : 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getButtonColor(BuildContext context) {
    if (isRecording) {
      return isPaused ? Colors.amber : Colors.red;
    } else {
      return Theme.of(context).primaryColor;
    }
  }
}