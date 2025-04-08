// timer_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicenotes/features/recording/recording_controller.dart';


class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingDuration = ref.watch(recordingControllerProvider).recordingDuration;
    final formattedDuration = _formatDuration(recordingDuration);
    return Text(
      formattedDuration,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return "$minutes:$seconds.$milliseconds";
  }
}
