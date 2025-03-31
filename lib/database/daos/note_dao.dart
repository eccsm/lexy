import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/note.dart';

part 'note_dao.g.dart';  
@DriftAccessor(tables: [Notes, Categories])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);
  
  // Get all notes
  Future<List<Note>> getAllNotes() {
    return (select(notes)..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])).get();
  }
  
  // Get a single note by ID
  Future<Note> getNoteById(int id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingle();
  }
  
  // Insert a new note
  Future<int> insertNote(NotesCompanion note) {
    return into(notes).insert(note);
  }
  
  // Update a note
  Future<bool> updateNote(Note note) {
    return update(notes).replace(note);
  }
  
  // Delete a note
  Future<int> deleteNote(int id) {
    return (delete(notes)..where((n) => n.id.equals(id))).go();
  }
  
  // Search notes
  Future<List<Note>> searchNotes(String searchTerm) {
    final term = '%$searchTerm%';
    return (select(notes)
      ..where((n) => n.title.like(term) | n.content.like(term))
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])
    ).get();
  }
  
  // Get notes by category
  Future<List<Note>> getNotesByCategory(int categoryId) {
    return (select(notes)
      ..where((n) => n.categoryId.equals(categoryId))
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])
    ).get();
  }
  
  // Get unsynced notes
  Future<List<Note>> getUnsyncedNotes() {
    return (select(notes)..where((n) => n.isSynced.equals(false))).get();
  }
  
  // Get the NoteWithCategory for a specific note
  Future<NoteWithCategory> getNoteWithCategory(int id) async {
    final note = await getNoteById(id);
    
    Category? category;
    if (note.categoryId != null) {
      category = await (select(categories)..where((c) => c.id.equals(note.categoryId!))).getSingleOrNull();
    }
    
    return NoteWithCategory(note: note, category: category);
  }
  
  // Get all notes with their categories
  Future<List<NoteWithCategory>> getAllNotesWithCategory() async {
    final allNotes = await getAllNotes();
    final List<NoteWithCategory> result = [];
    
    for (final note in allNotes) {
      Category? category;
      if (note.categoryId != null) {
        category = await (select(categories)..where((c) => c.id.equals(note.categoryId!))).getSingleOrNull();
      }
      
      result.add(NoteWithCategory(note: note, category: category));
    }
    
    return result;
  }
  
  // Get notes by category with their category data
  Future<List<NoteWithCategory>> getNotesByCategoryWithData(int categoryId) async {
    final notesInCategory = await getNotesByCategory(categoryId);
    final category = await (select(categories)..where((c) => c.id.equals(categoryId))).getSingle();
    
    return notesInCategory.map((note) => NoteWithCategory(note: note, category: category)).toList();
  }
}