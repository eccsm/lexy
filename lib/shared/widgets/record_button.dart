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
      onLongPress: isRecording ? onStopRecording : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _getButtonColor(),
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
          child: Icon(
            _getButtonIcon(),
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Color _getButtonColor() {
    if (!isRecording) {
      return Colors.red;
    } else if (isPaused) {
      return Colors.orange;
    } else {
      return Colors.red.shade800;
    }
  }
  
  IconData _getButtonIcon() {
    if (!isRecording) {
      return Icons.mic;
    } else if (isPaused) {
      return Icons.play_arrow;
    } else {
      return Icons.pause;
    }
  }
}