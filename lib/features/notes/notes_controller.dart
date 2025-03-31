import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import '../../database/app_database.dart';

final Logger _logger = Logger();

// Search term state
final searchTermProvider = StateProvider<String>((ref) => '');

// All notes provider
final notesProvider = FutureProvider<List<NoteWithCategory>>((ref) async {
  final database = ref.watch(databaseProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  if (searchTerm.isEmpty) {
    return database.noteDao.getAllNotesWithCategory();
  } else {
    // When searching, we need to join the notes with categories manually
    final notes = await database.noteDao.searchNotes(searchTerm);
    final List<NoteWithCategory> result = [];
    
    for (final note in notes) {
      Category? category;
      if (note.categoryId != null) {
        category = await database.categoryDao.getCategoryById(note.categoryId!);
      }
      
      result.add(NoteWithCategory(note: note, category: category));
    }
    
    return result;
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
  return database.noteDao.getNotesByCategoryWithData(categoryId);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.categoryDao.getAllCategories();
});

// Controller for note operations
class NotesController {
  final AppDatabase _database;
  
  NotesController(this._database);
  
  Future<void> deleteNote(int id) async {
    await _database.noteDao.deleteNote(id);
  }
  
  Future<void> updateNote(Note note) async {
    await _database.noteDao.updateNote(note);
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
    
    for (final note in unsyncedNotes) {
      try {
        // Sync note to cloud
        
        // Update local note with synced status
        await _database.noteDao.updateNote(
          note.copyWith(isSynced: true),
        );
      } catch (e) {
        _logger.e('Failed to sync note ${note.id}: $e');
      }
    }
  }
}

final notesControllerProvider = Provider<NotesController>((ref) {
  final database = ref.watch(databaseProvider);
  return NotesController(database);
});