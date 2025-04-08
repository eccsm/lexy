import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicenotes/shared/widgets/app_bar.dart';

import '../../shared/widgets/audio_visualizer.dart';
import '../../shared/widgets/record_button.dart';
import '../../shared/widgets/timer_display.dart';
import 'recording_controller.dart';


class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingControllerProvider);
    final controller = ref.read(recordingControllerProvider.notifier);
    _handleErrorMessage(recordingState, controller);

    return Scaffold(
      // Use your custom AppBar widget
      appBar: CustomAppBar(
        title: 'New Recording',
        showBackButton: true,
        showProfileButton: false, // or true if you like
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              if (recordingState.isRecording || recordingState.isPaused)
                _buildRecordingInfo(recordingState)
              else
                _buildTitleInput(controller),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: AudioVisualizer(
                    isRecording: recordingState.isRecording,
                    amplitude: recordingState.currentAmplitude,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildRecordingControls(recordingState, controller),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _handleErrorMessage(RecordingState recordingState, RecordingController controller) {
    if (recordingState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(recordingState.errorMessage!),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          controller.clearErrorMessage();
        }
      });
    }
  }

  Widget _buildRecordingInfo(RecordingState recordingState) {
    return Column(
      children: [
        const TimerDisplay(),
        const SizedBox(height: 8),
        _buildDurationIndicator(recordingState.recordingDuration),
      ],
    );
  }

  Widget _buildTitleInput(RecordingController controller) {
    return TextField(
      controller: controller.titleController,
      decoration: const InputDecoration(
        hintText: 'Note title (optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRecordingControls(
      RecordingState recordingState, RecordingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (recordingState.isRecording || recordingState.isPaused)
          IconButton(
            onPressed: controller.cancelRecording,
            icon: const Icon(Icons.delete_outline),
            iconSize: 32,
            color: Colors.red,
          ),
        const SizedBox(width: 24),
        RecordButton(
          isRecording: recordingState.isRecording,
          isPaused: recordingState.isPaused,
          onStartRecording: controller.startRecording,
          onPauseRecording: controller.pauseRecording,
          onResumeRecording: controller.resumeRecording,
          onStopRecording: controller.stopRecording,
        ),
        const SizedBox(width: 24),
        if (recordingState.isRecording || recordingState.isPaused)
          IconButton(
            onPressed: controller.isRecordingDurationSufficient
                ? controller.stopRecording
                : null,
            icon: const Icon(Icons.check_circle_outline),
            iconSize: 32,
            color: controller.isRecordingDurationSufficient
                ? Colors.green
                : Colors.grey,
          ),
      ],
    );
  }

  Widget _buildDurationIndicator(Duration duration) {
    final isSufficient = duration.inMilliseconds >= 500;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSufficient ? Icons.check_circle : Icons.timer,
          color: isSufficient ? Colors.green : Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          isSufficient
              ? 'Recording length is sufficient'
              : 'Keep recording (minimum 0.5s)',
          style: TextStyle(
            fontSize: 12,
            color: isSufficient ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}
