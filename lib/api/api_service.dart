import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';

import '../database/models/note.dart';
import 'models/note.dart';
import 'models/transcription_response.dart';

class ApiService {
  final Dio _dio;
  final String _baseUrl;
  final Logger _logger = Logger();
  
  ApiService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl {
    _dio.options.baseUrl = _baseUrl;
    
    // Add authorization interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add token if available
          final token = _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
  
  String? _getAuthToken() {
    // Get token from secure storage
    // This should be implemented using flutter_secure_storage
    return null;
  }
  
  // Transcribe audio using your existing Spring Boot endpoint
  Future<TranscriptionResponse> transcribeAudio(File audioFile, String? prompt) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'model': 'whisper-1',
        if (prompt != null) 'prompt': prompt,
      });
      
      final response = await _dio.post(
        '/api/audio/transcribe',
        data: formData,
      );
      
      return TranscriptionResponse.fromJson(response.data);
    } catch (e) {
      _logger.e('Error transcribing audio: $e');
      throw Exception('Failed to transcribe audio: $e');
    }
  }
  
  // Sync a note to the server
  Future<ApiNote> syncNote(Notes note) async {
    try {
      final response = await _dio.post(
        '/api/notes',
        data: {
          'title': note.title,
          'content': note.content,
          'createdAt': note.createdAt.toString(),
          'updatedAt': note.updatedAt.toString(),
          'categoryId': note.categoryId,
        },
      );
      
      return ApiNote.fromJson(response.data);
    } catch (e) {
      _logger.e('Error syncing note: $e');
      throw Exception('Failed to sync note: $e');
    }
  }
  
  // Get all notes from the server
  Future<List<ApiNote>> getNotes() async {
    try {
      final response = await _dio.get('/api/notes');
      
      return (response.data as List)
        .map((data) => ApiNote.fromJson(data))
        .toList();
    } catch (e) {
      _logger.e('Error fetching notes: $e');
      throw Exception('Failed to fetch notes: $e');
    }
  }
  
  // Get a single note by ID
  Future<ApiNote> getNoteById(String id) async {
    try {
      final response = await _dio.get('/api/notes/$id');
      
      return ApiNote.fromJson(response.data);
    } catch (e) {
      _logger.e('Error fetching note: $e');
      throw Exception('Failed to fetch note: $e');
    }
  }
  
  // Delete a note
  Future<void> deleteNote(String id) async {
    try {
      await _dio.delete('/api/notes/$id');
    } catch (e) {
      _logger.e('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<TranscriptionResponse> transcribeAudioBytes(
  Uint8List audioBytes, {
  required String fileName,
  String? title,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: fileName,
        contentType: MediaType('audio', 'webm'),
      ),
      'model': 'whisper-1',
      if (title != null) 'prompt': title,
    });

    final response = await _dio.post(
      '/api/audio/transcribe',
      data: formData,
    );

    return TranscriptionResponse.fromJson(response.data);
  } catch (e) {
    _logger.e('Error transcribing audio bytes: $e');
    throw Exception('Failed to transcribe audio bytes: $e');
  }
}
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = Dio();
  
  // Add logging interceptor in debug mode
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
  
  return ApiService(
    dio: dio,
    baseUrl: 'http://10.0.2.2:8080', // Default for Android emulator to localhost
  );
});

