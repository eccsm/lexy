import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:voicenotes/shared/utils/js_utils_stub.dart'
    if (dart.library.html) 'package:voicenotes/shared/utils/js_utils.dart';

import '../../api/api_service.dart';
import '../../database/app_database.dart';

/// Recording state with possible inMemoryData for web
class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration recordingDuration;
  final double currentAmplitude;
  final String? filePath;
  final Uint8List? inMemoryData;

  const RecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.recordingDuration = Duration.zero,
    this.currentAmplitude = 0.0,
    this.filePath,
    this.inMemoryData,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? recordingDuration,
    double? currentAmplitude,
    String? filePath,
    Uint8List? inMemoryData,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      filePath: filePath ?? this.filePath,
      inMemoryData: inMemoryData ?? this.inMemoryData,
    );
  }
}

class RecordingController extends StateNotifier<RecordingState> {
  final ApiService _apiService;
  final AppDatabase _database;
  FlutterSoundRecorder? _recorder;
  final TextEditingController titleController = TextEditingController();

  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  
  final List<int> _recordedDataBuffer = [];
  final StreamController<Uint8List> _recordedDataController = 
      StreamController<Uint8List>();
  
  bool _isInitialized = false;

  RecordingController(this._apiService, this._database)
      : super(const RecordingState()) {
    _initRecorder();
  }

    Codec _getBestCodecForWeb() {
    if (kIsWeb) {
      final userAgent = getUserAgent().toLowerCase();
      if (userAgent.contains('chrome')) {
        return Codec.opusWebM;
      } else if (userAgent.contains('firefox')) {
        return Codec.opusWebM;
      } else if (userAgent.contains('safari')) {
        return Codec.aacMP4;
      }
    }
    return Codec.aacADTS;
  }


    Future<void> _initRecorder() async {
    if (_isInitialized) return;
    
    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          debugPrint('Microphone permission denied');
          return;
        }
      }

      _recorder = FlutterSoundRecorder();
      
      if (kIsWeb) {
        debugPrint('Web audio context: relying on default browser behavior');
      }
      
      await _recorder?.openRecorder();
      _isInitialized = true;
      debugPrint('Recorder initialized successfully');
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }


  Future<void> startRecording() async {
    if (state.isRecording) return;
    
    try {
      // Ensure recorder is initialized
      if (!_isInitialized) {
        await _initRecorder();
      }
      
      // Make sure recorder is not null
      if (_recorder == null) {
        debugPrint('Recorder is null, cannot start recording');
        return;
      }
      
      _recordedDataBuffer.clear();
      
      // Setup stream listener for web
      if (kIsWeb) {
        _recordedDataController.stream.listen((data) {
          _recordedDataBuffer.addAll(data);
        });
      }
      
      String? path;
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        path = '${directory.path}/${const Uuid().v4()}.aac';
      }
      
      final codec = _getBestCodecForWeb();
      debugPrint('Starting recorder with codec: ${codec.name}');
      
      await _recorder?.startRecorder(
        codec: codec,
        toFile: path,
        toStream: kIsWeb ? _recordedDataController.sink : null,
      );
      
      debugPrint('Recorder started successfully');
      
      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        filePath: path,
        recordingDuration: Duration.zero,
      );
      
      _startTimers();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused || _recorder == null) return;
    
    try {
      await _recorder?.pauseRecorder();
      state = state.copyWith(isPaused: true);
      _stopTimers();
      debugPrint('Recording paused');
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    if (!state.isPaused || _recorder == null) return;
    
    try {
      await _recorder?.resumeRecorder();
      state = state.copyWith(isPaused: false);
      _startTimers();
      debugPrint('Recording resumed');
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  Future<void> stopRecording() async {
    if ((!state.isRecording && !state.isPaused) || _recorder == null) return;
    
    try {
      _stopTimers();
      final path = await _recorder?.stopRecorder();
      debugPrint('Recording stopped, path: $path');
      
      // Process the recording
      if (!kIsWeb && state.filePath != null) {
        await _processRecording(filePath: state.filePath!);
      } else if (kIsWeb && _recordedDataBuffer.isNotEmpty) {
        final recordedBytes = Uint8List.fromList(_recordedDataBuffer);
        state = state.copyWith(inMemoryData: recordedBytes);
        await _processRecording(inMemoryData: recordedBytes);
      }
      
      // Reset state
      state = const RecordingState();
      titleController.clear();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    if ((!state.isRecording && !state.isPaused) || _recorder == null) return;
    
    try {
      _stopTimers();
      await _recorder?.stopRecorder();
      
      // Delete file if on mobile
      if (!kIsWeb && state.filePath != null) {
        try {
          final file = File(state.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }
      
      // Reset state
      _recordedDataBuffer.clear();
      state = const RecordingState();
      titleController.clear();
      debugPrint('Recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  void _startTimers() {
    _stopTimers();
    
    debugPrint('Starting timers');
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newDuration = state.recordingDuration + const Duration(seconds: 1);
      state = state.copyWith(recordingDuration: newDuration);
    });
    
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      // Simplified amplitude calculation
      if (state.isRecording) {
        try {
          // Simulate amplitude for UI visualization
          final amplitude = 40.0 + (DateTime.now().millisecondsSinceEpoch % 25);
          state = state.copyWith(currentAmplitude: amplitude);
        } catch (e) {
          // Ignore amplitude errors
        }
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  Future<void> _processRecording({
    String? filePath,
    Uint8List? inMemoryData,
  }) async {
    try {
      final title = titleController.text.trim();
      final defaultTitle = 'Voice Note ${DateTime.now().toString().substring(0, 16)}';
      
      if (kIsWeb && inMemoryData != null) {
        final transcription = await _apiService.transcribeAudioBytes(
          inMemoryData,
          fileName: '${const Uuid().v4()}.webm',
          title: title.isNotEmpty ? title : null,
        );
        
        await _database.noteDao.insertNote(
          NotesCompanion.insert(
            title: title.isNotEmpty ? title : defaultTitle,
            content: transcription.text,
            audioPath: const Value(null),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: const Value(false),
            categoryId: const Value(null),
          ),
        );
      } else if (filePath != null) {
        final file = File(filePath);
        final transcription = await _apiService.transcribeAudio(
          file, 
          title.isNotEmpty ? title : null,
        );
        
        await _database.noteDao.insertNote(
          NotesCompanion.insert(
            title: title.isNotEmpty ? title : defaultTitle,
            content: transcription.text,
            audioPath: Value(filePath),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: const Value(false),
            categoryId: const Value(null),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing recording: $e');
    }
  }

  @override
  void dispose() {
    _stopTimers();
    _recordedDataController.close();
    _recorder?.closeRecorder();
    titleController.dispose();
    super.dispose();
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final database = ref.watch(databaseProvider);
  return RecordingController(apiService, database);
});