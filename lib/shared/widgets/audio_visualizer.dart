import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  final int barCount;
  final Color activeColor;
  final Color inactiveColor;

  const AudioVisualizer({
    super.key,
    required this.isRecording,
    required this.amplitude,
    this.barCount = 30,
    this.activeColor = const Color(0xFF6750A4),
    this.inactiveColor = Colors.grey,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _barHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Initialize bar heights
    _resetBarHeights();
    
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    _animationController.addListener(() {
      if (widget.isRecording) {
        _updateBarHeights();
      }
    });
    
    if (widget.isRecording) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _resetBarHeights();
      }
    }
    
    if (widget.barCount != oldWidget.barCount) {
      _resetBarHeights();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetBarHeights() {
    _barHeights.clear();
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.1);
    }
  }

  void _updateBarHeights() {
    if (mounted) {
      setState(() {
        // Scale amplitude to a reasonable range (0.1 to 1.0)
        final scaledAmplitude = 0.1 + min(0.9, widget.amplitude / 80);
        
        for (int i = 0; i < _barHeights.length; i++) {
          if (widget.isRecording) {
            // Create a randomized effect based on the amplitude
            _barHeights[i] = 0.1 + (_random.nextDouble() * scaledAmplitude);
          } else {
            _barHeights[i] = 0.1;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          _barHeights.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 4,
            height: 20 + (_barHeights[index] * 160),
            decoration: BoxDecoration(
              color: widget.isRecording
                  ? widget.activeColor
                  : widget.inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}