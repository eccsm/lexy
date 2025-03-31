import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_service.dart';
import '../../database/app_database.dart';


// Recording state
class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration recordingDuration;
  final double currentAmplitude;
  final String? filePath;
  
  RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.recordingDuration = Duration.zero,
    this.currentAmplitude = 0.0,
    this.filePath,
  });
  
  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? recordingDuration,
    double? currentAmplitude,
    String? filePath,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      filePath: filePath ?? this.filePath,
    );
  }
}

// Controller
class RecordingController extends StateNotifier<RecordingState> {
  final ApiService _apiService;
  final AppDatabase _database;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController titleController = TextEditingController();
  
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  
  RecordingController(this._apiService, this._database) 
      : super(RecordingState()) {
    _initRecorder();
  }
  
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    
    await _recorder.openRecorder();
  }
  
  Future<void> startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${const Uuid().v4()}.aac';
      final filePath = '${tempDir.path}/$fileName';
      
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      
      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        filePath: filePath,
      );
      
      _startTimers();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }
  
  Future<void> pauseRecording() async {
    if (state.isRecording) {
      await _recorder.pauseRecorder();
      
      state = state.copyWith(
        isPaused: true,
      );
      
      _stopTimers();
    }
  }
  
  Future<void> resumeRecording() async {
    if (state.isPaused) {
      await _recorder.resumeRecorder();
      
      state = state.copyWith(
        isPaused: false,
      );
      
      _startTimers();
    }
  }
  
  Future<void> stopRecording() async {
    if (state.isRecording || state.isPaused) {
      _stopTimers();
      
      await _recorder.stopRecorder();
      
      final filePath = state.filePath;
      if (filePath != null) {
        await _processRecording(filePath);
      }
      
      state = RecordingState();
      titleController.clear();
    }
  }
  
  Future<void> cancelRecording() async {
    if (state.isRecording || state.isPaused) {
      _stopTimers();
      
      await _recorder.stopRecorder();
      
      // Delete the recorded file
      final filePath = state.filePath;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      state = RecordingState();
      titleController.clear();
    }
  }
  
  void _startTimers() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        recordingDuration: state.recordingDuration + const Duration(seconds: 1),
      );
    });
    
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_recorder.isRecording) {
        final amplitude = await _recorder.getRecorderState();
        state = state.copyWith(
          currentAmplitude: amplitude.decibels ?? 0.0,
        );
      }
    });
  }
  
  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }
  
  Future<void> _processRecording(String filePath) async {
    try {
      // Send file to backend for transcription
      final title = titleController.text.trim();
      final transcription = await _apiService.transcribeAudio(
        File(filePath),
        title.isNotEmpty ? title : null,
      );
      
      // Save to database
      await _database.noteDao.insertNote(
        NoteCompanion.insert(
          title: title.isNotEmpty ? title : 'Note ${DateTime.now().toString()}',
          content: transcription.text,
          audioPath: filePath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: false,
        ),
      );
    } catch (e) {
      debugPrint('Error processing recording: $e');
    }
  }
  
  @override
  void dispose() {
    _stopTimers();
    _recorder.closeRecorder();
    titleController.dispose();
    super.dispose();
  }
}

final recordingControllerProvider = StateNotifierProvider<RecordingController, RecordingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final database = ref.watch(databaseProvider);
  return RecordingController(apiService, database);
});