import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_notes/api/api_service.dart';
import 'package:voice_notes/database/app_database.dart';
import 'package:voice_notes/database/models/note.dart';

import '../../api/api_service.dart';
import '../../database/app_database.dart';
import '../../database/daos/note_dao.dart';

// Search term state
final searchTermProvider = StateProvider<String>((ref) => '');

// All notes provider
final notesProvider = FutureProvider<List<NoteWithCategory>>((ref) async {
  final database = ref.watch(databaseProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  if (searchTerm.isEmpty) {
    return database.noteDao.getAllNotesWithCategory();
  } else {
    return database.noteDao.searchNotes(searchTerm);
  }
});

// Single note provider
final noteProvider = FutureProvider.family<NoteWithCategory, String>((ref, id) async {
  final database = ref.watch(databaseProvider);
  return database.noteDao.getNoteWithCategory(int.parse(id));
});

// Notes by category provider
final notesByCategoryProvider = FutureProvider.family<List<NoteWithCategory>, int>((ref, categoryId) async {
  final database = ref.watch(databaseProvider);
  return database.noteDao.getNotesByCategory(categoryId);
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
    await _database.noteDao.deleteNote(id);
  }
  
  Future<void> updateNote(Note note) async {
    await _database.noteDao.updateNote(note);
  }
  
  Future<void> syncNotes() async {
    final unsyncedNotes = await _database.noteDao.getUnsyncedNotes();
    
    for (final note in unsyncedNotes) {
      try {
        // Sync note to cloud
        final syncedNote = await _apiService.syncNote(note);
        
        // Update local note with synced status
        await _database.noteDao.updateNote(
          note.copyWith(isSynced: true),
        );
      } catch (e) {
        // Handle sync error
        print('Failed to sync note ${note.id}: $e');
      }
    }
  }
}

final notesControllerProvider = Provider<NotesController>((ref) {
  final database = ref.watch(databaseProvider);
  final apiService = ref.watch(apiServiceProvider);
  return NotesController(database, apiService);
});