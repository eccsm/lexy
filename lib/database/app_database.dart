import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/category_dao.dart';
import 'daos/note_dao.dart';
import 'daos/tag_dao.dart';
import 'models/note.dart';


import 'package:sqlite3/sqlite3.dart';
import 'package:drift/native.dart';
import 'package:drift/wasm.dart';

import 'package:voicenotes/database/schema.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notes, Categories, Tags, NoteTags], daos: [CategoryDao, TagDao, NoteDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) async {
        // Use the generated schema creator instead of createAll()
        await createV1(m);
        
        // Then seed your initial data as before
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
      onUpgrade: (Migrator m, int from, int to) async {
        // This will be used in the future when you have more schema versions
      },
      beforeOpen: (details) async {
        // Optional: validate the schema matches what we expect
        await validateDatabaseSchema(details as QueryExecutor);
      },
    );

  // DAOs remain the same
  @override
  CategoryDao get categoryDao => CategoryDao(this);
  @override
  TagDao get tagDao => TagDao(this);
  @override
  NoteDao get noteDao => NoteDao(this);
  
  // Keep all your existing database operations
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

// Platform-specific database connection
QueryExecutor _openConnection() {
  if (kIsWeb) {
    return _connectWeb();
  } else {
    return _connectMobile();
  }
}

// Web connection using WASM
QueryExecutor _connectWeb() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'voice_notes_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Handle cases where certain browser features are unavailable
      print('Using ${result.chosenImplementation} due to missing features: ${result.missingFeatures}');
    }

    return result.resolvedExecutor;
  }));
}


// Mobile connection (iOS, Android, etc.)
LazyDatabase _connectMobile() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'voice_notes.db'));


    // Set proper temp directory
    final cacheDir = await getTemporaryDirectory();
    sqlite3.tempDirectory = cacheDir.path;

    return NativeDatabase.createInBackground(file);
  });
}

// For use in the app
class NoteWithCategory {
  final Note note;
  final Category? category;

  NoteWithCategory({
    required this.note,
    this.category,
  });
}