import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/recording/recording_controller.dart';
import '../utils/date_formatter.dart';


class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingControllerProvider);
    final duration = recordingState.recordingDuration;
    
    return Column(
      children: [
        // Recording indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (recordingState.isPaused)
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RECORDING',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Timer
        Text(
          formatDuration(duration),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}