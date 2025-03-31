import 'package:drift/drift.dart';
import 'package:voicenotes/database/app_database.dart';
import 'package:voicenotes/database/models/note.dart';

part '../dao/note_dao.g.dart';

@DriftAccessor(tables: [Notes, Categories, Tags, NoteTags])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(AppDatabase db) : super(db);
  
  // Join result for note with its category
  Future<List<NoteWithCategory>> getAllNotesWithCategory() {
    final query = select(notes)
      .join(
        leftOuterJoin(
          categories,
          categories.id.equalsExp(notes.categoryId),
        ),
      );
      
    query.orderBy([OrderingTerm.desc(notes.updatedAt)]);
      
    return query.map((row) {
      return NoteWithCategory(
        note: row.readTable(notes),
        category: row.readTableOrNull(categories),
      );
    }).get();
  }
  
  // Get a single note with its category
  Future<NoteWithCategory> getNoteWithCategory(int id) {
    final query = select(notes)
      .join(
        leftOuterJoin(
          categories,
          categories.id.equalsExp(notes.categoryId),
        ),
      );
      
    query.where(notes.id.equals(id));
      
    return query.map((row) {
      return NoteWithCategory(
        note: row.readTable(notes),
        category: row.readTableOrNull(categories),
      );
    }).getSingle();
  }
  
  // Search notes by content or title
  Future<List<NoteWithCategory>> searchNotes(String searchTerm) {
    final query = select(notes)
      .join(
        leftOuterJoin(
          categories,
          categories.id.equalsExp(notes.categoryId),
        ),
      );
      
    query.where(
      notes.title.like('%$searchTerm%').or(notes.content.like('%$searchTerm%')),
    );
      
    query.orderBy([OrderingTerm.desc(notes.updatedAt)]);
      
    return query.map((row) {
      return NoteWithCategory(
        note: row.readTable(notes),
        category: row.readTableOrNull(categories),
      );
    }).get();
  }
  
  // Get notes by category
  Future<List<NoteWithCategory>> getNotesByCategory(int categoryId) {
    final query = select(notes)
      .join(
        leftOuterJoin(
          categories,
          categories.id.equalsExp(notes.categoryId),
        ),
      );
      
    query.where(notes.categoryId.equals(categoryId));
    query.orderBy([OrderingTerm.desc(notes.updatedAt)]);
      
    return query.map((row) {
      return NoteWithCategory(
        note: row.readTable(notes),
        category: row.readTableOrNull(categories),
      );
    }).get();
  }
  
  // Get notes that haven't been synced
  Future<List<Note>> getUnsyncedNotes() {
    return (select(notes)..where((n) => n.isSynced.equals(false))).get();
  }
  
  // Basic CRUD operations
  Future<int> insertNote(NotesCompanion note) {
    return into(notes).insert(note);
  }
  
  Future<bool> updateNote(Note note) {
    return update(notes).replace(note);
  }
  
  Future<int> deleteNote(int id) {
    return (delete(notes)..where((n) => n.id.equals(id))).go();
  }
}

// Join result class
class NoteWithCategory {
  final Note note;
  final Category? category;
  
  NoteWithCategory({
    required this.note,
    this.category,
  });
}