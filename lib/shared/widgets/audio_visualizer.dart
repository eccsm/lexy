import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  
  const AudioVisualizer({
    super.key,
    required this.isRecording,
    required this.amplitude,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _amplitudeHistory = List.filled(30, 0);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Update amplitude history
    if (widget.isRecording) {
      _amplitudeHistory.removeAt(0);
      _amplitudeHistory.add(widget.amplitude.isNaN ? 0 : widget.amplitude);
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _AudioWaveformPainter(
            isRecording: widget.isRecording,
            amplitudeHistory: _amplitudeHistory,
            animationValue: _animationController.value,
          ),
        );
      },
    );
  }
}

class _AudioWaveformPainter extends CustomPainter {
  final bool isRecording;
  final List<double> amplitudeHistory;
  final double animationValue;
  
  _AudioWaveformPainter({
    required this.isRecording,
    required this.amplitudeHistory,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRecording ? Colors.red : Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    if (!isRecording) {
      // Draw a flat line when not recording
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    
    // Draw the waveform
    final barWidth = size.width / amplitudeHistory.length;
    final center = size.height / 2;
    
    for (int i = 0; i < amplitudeHistory.length; i++) {
      final amplitude = amplitudeHistory[i];
      final normalized = math.min(amplitude / 60, 1.0);
      
      // Calculate bar height with slight animation
      final barHeight = normalized * size.height * 0.8 * (1 + animationValue * 0.1);
      
      // Draw the bar
      canvas.drawLine(
        Offset(i * barWidth, center - barHeight / 2),
        Offset(i * barWidth, center + barHeight / 2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_AudioWaveformPainter oldDelegate) => 
      isRecording || oldDelegate.isRecording || 
      animationValue != oldDelegate.animationValue;
}