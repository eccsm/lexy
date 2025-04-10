// lib/features/notes/notes_controller.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:voicenotes/database/models/note.dart';
import '../../database/app_database.dart';
import '../../api/api_service.dart';
import '../../providers.dart';

final Logger _logger = Logger();

// Search term state
final searchTermProvider = StateProvider<String>((ref) => '');

// All notes provider
final notesProvider = FutureProvider<List<NoteWithCategory>>((ref) async {
  final database = ref.watch(databaseProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  if (searchTerm.isEmpty) {
    final notes = await database.getAllNotesWithCategory();
    return _applySorting(notes, ref.watch(sortOptionProvider));
  } else {
    // When searching, we need to join the notes with categories manually
    final notes = await database.searchNotes(searchTerm);
    final List<NoteWithCategory> result = [];
    
    for (final note in notes) {
      Category? category;
      if (note.categoryId != null) {
        category = await database.categoryDao.getCategoryById(note.categoryId!);
      }
      
      result.add(NoteWithCategory(note: note, category: category));
    }
    
    return _applySorting(result, ref.watch(sortOptionProvider));
  }
});

// Helper function to apply sorting based on the selected option
List<NoteWithCategory> _applySorting(List<NoteWithCategory> notes, NoteSortOption sortOption) {
  switch (sortOption) {
    case NoteSortOption.newest:
      return notes..sort((a, b) => b.note.createdAt.compareTo(a.note.createdAt));
    case NoteSortOption.oldest:
      return notes..sort((a, b) => a.note.createdAt.compareTo(b.note.createdAt));
    case NoteSortOption.alphabetical:
      return notes..sort((a, b) => a.note.title.toLowerCase().compareTo(b.note.title.toLowerCase()));
    case NoteSortOption.recentlyUpdated:
      return notes..sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
  }
}

// Single note provider
final noteProvider = FutureProvider.family<NoteWithCategory, int>((ref, noteId) async {
  final database = ref.watch(databaseProvider);
  return database.getNoteWithCategory(noteId);
});

// Notes by category provider
final notesByCategoryProvider = FutureProvider.family<List<NoteWithCategory>, int>((ref, categoryId) async {
  final database = ref.watch(databaseProvider);
  return database.getNotesByCategory(categoryId);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.categoryDao.getAllCategories();
});

// Controller for note operations
class NotesController {
  final AppDatabase _database;
  final ApiService _apiService;
  
  NotesController(this._database, this._apiService);
  
  Future<void> deleteNote(int id) async {
    // First get the note to check if it has an audio file
    final note = await _database.noteDao.getNoteById(id);
    
    // Delete audio file if it exists
    if (note.audioPath != null) {
      try {
        final file = File(note.audioPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Deleted audio file: ${note.audioPath}');
        }
      } catch (e) {
        _logger.e('Error deleting audio file: $e');
        // Continue with note deletion even if audio deletion fails
      }
    }
    
    // Delete the note from database
    await _database.noteDao.deleteNote(id);
    _logger.i('Deleted note with ID: $id');
  }
  
  Future<void> updateNote(Note note) async {
    await _database.noteDao.updateNote(note);
    _logger.i('Updated note with ID: ${note.id}');
  }
  
  Future<void> updateNoteContent(int id, String title, String content, {int? categoryId}) async {
    final note = await _database.noteDao.getNoteById(id);
    final updatedNote = note.copyWith(
      title: title,
      content: content,
      categoryId: Value(categoryId),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _database.noteDao.updateNote(updatedNote);
    _logger.i('Updated note content for ID: $id');
  }
  
  Future<void> removeAudioFromNote(int id) async {
    final note = await _database.noteDao.getNoteById(id);
    
    if (note.audioPath != null) {
      try {
        final file = File(note.audioPath!);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Deleted audio file: ${note.audioPath}');
        }
      } catch (e) {
        _logger.e('Error deleting audio file: $e');
        throw Exception('Failed to delete audio file: $e');
      }
    }
    
    final updatedNote = note.copyWith(
      audioPath: const Value(null),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    
    await _database.noteDao.updateNote(updatedNote);
    _logger.i('Removed audio from note ID: $id');
  }
  
  Future<int> createNote({
    required String title,
    required String content,
    String? audioPath,
    int? categoryId
  }) async {
    return await _database.noteDao.insertNote(
      NotesCompanion.insert(
        title: title,
        content: content,
        audioPath: Value(audioPath),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryId: Value(categoryId),
      )
    );
  }
  
  Future<void> syncNotes() async {
    final unsyncedNotes = await _database.noteDao.getUnsyncedNotes();
    _logger.i('Found ${unsyncedNotes.length} unsynced notes');
    
    for (final note in unsyncedNotes) {
      try {
        // Sync note to cloud
        await _apiService.syncNote(note as Notes);
        
        // Update local note with synced status
        await _database.noteDao.updateNote(
          note.copyWith(isSynced: true),
        );
        _logger.i('Successfully synced note ID: ${note.id}');
      } catch (e) {
        _logger.e('Failed to sync note ${note.id}: $e');
      }
    }
  }
}

final notesControllerProvider = Provider<NotesController>((ref) {
  final database = ref.watch(databaseProvider);
  final apiService = ref.watch(apiServiceProvider);
  return NotesController(database, apiService);
});