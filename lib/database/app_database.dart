import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/category_dao.dart';
import 'daos/note_dao.dart';
import 'daos/tag_dao.dart';
import 'models/note.dart';

part 'app_database.g.dart';  // This file will be generated



@DriftDatabase(tables: [Notes, Categories, Tags, NoteTags], daos: [CategoryDao, TagDao, NoteDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          
          // Create default categories
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Work',
              color: const Color(0xFF4CAF50).value,
              icon: const Value('work'),
            ),
          );

          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Personal',
              color: const Color(0xFF2196F3).value,
              icon: const Value('person'),
            ),
          );

          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Ideas',
              color: const Color(0xFFFFC107).value,
              icon: const Value('lightbulb'),
            ),
          );
        },
      );

  // Helpers for DAOs
  @override
  CategoryDao get categoryDao => CategoryDao(this);
  @override
  TagDao get tagDao => TagDao(this);
  @override
  NoteDao get noteDao => NoteDao(this);
  
  // Note operations
  Future<List<NoteWithCategory>> getAllNotesWithCategory() async {
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ]);
    
    query.orderBy([OrderingTerm.desc(notes.updatedAt)]);
    
    final rows = await query.get();
    
    return rows.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);
      
      return NoteWithCategory(note: note, category: category);
    }).toList();
  }
  
  Future<NoteWithCategory> getNoteWithCategory(int id) async {
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ]);
    
    query.where(notes.id.equals(id));
    
    final row = await query.getSingle();
    
    return NoteWithCategory(
      note: row.readTable(notes), 
      category: row.readTableOrNull(categories)
    );
  }
  
  Future<List<NoteWithCategory>> getNotesByCategory(int categoryId) async {
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ]);
    
    query.where(notes.categoryId.equals(categoryId));
    query.orderBy([OrderingTerm.desc(notes.updatedAt)]);
    
    final rows = await query.get();
    
    return rows.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);
      
      return NoteWithCategory(note: note, category: category);
    }).toList();
  }
  
  Future<List<Note>> searchNotes(String searchTerm) async {
    final term = '%$searchTerm%';
    
    final query = select(notes)
      ..where((n) => n.title.like(term) | n.content.like(term));
    
    return query.get();
  }
  
  Future<List<Note>> getUnsyncedNotes() async {
    final query = select(notes)
      ..where((n) => n.isSynced.equals(false));
    
    return query.get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'voice_notes.db'));
    return NativeDatabase(file);
  });
}

// Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  ref.onDispose(() async {
    await database.close();
  });
  
  return database;
});

// For use in the app
class NoteWithCategory {
  final Note note;
  final Category? category;

  NoteWithCategory({
    required this.note,
    this.category,
  });
}