import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_bar.dart';
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
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'New Recording',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Recording info or title input
              if (recordingState.isRecording || recordingState.isPaused)
                const TimerDisplay()
              else
                TextField(
                  controller: controller.titleController,
                  decoration: const InputDecoration(
                    hintText: 'Note title (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Audio visualization
              Expanded(
                child: Center(
                  child: AudioVisualizer(
                    isRecording: recordingState.isRecording,
                    amplitude: recordingState.currentAmplitude,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Recording controls
              Row(
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
                      onPressed: controller.stopRecording,
                      icon: const Icon(Icons.check_circle_outline),
                      iconSize: 32,
                      color: Colors.green,
                    ),
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}