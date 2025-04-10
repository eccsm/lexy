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
  final List<double> _barHeights = List.filled(30, 0.0);
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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
    // Update bar heights based on amplitude when recording
    if (widget.isRecording) {
      _updateBarHeights(widget.amplitude);
    } else {
      // Reset bars when not recording
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = 0.0;
      }
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_barHeights.length, (index) {
                // Apply a small animation effect
                final animatedHeight = widget.isRecording 
                    ? _barHeights[index] * (0.9 + 0.1 * _animationController.value)
                    : 0.0;
                
                return _buildBar(context, animatedHeight);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar(BuildContext context, double height) {
    return Container(
      width: 4,
      height: height * 200, // Scale to fit the 200 height container
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _updateBarHeights(double amplitude) {
    // Ensure amplitude is in valid range (0.0 to 1.0)
    final normalizedAmplitude = amplitude.clamp(0.0, 1.0);
    
    // Update bars with smooth transitions
    for (int i = 0; i < _barHeights.length; i++) {
      // Add randomness for a more natural look
      final randomFactor = 0.7 + 0.3 * _random.nextDouble();
      
      // Calculate new height with some randomness
      final targetHeight = normalizedAmplitude * randomFactor;
      
      // Smooth transition (30% old value, 70% new value)
      _barHeights[i] = _barHeights[i] * 0.3 + targetHeight * 0.7;
    }
  }
}