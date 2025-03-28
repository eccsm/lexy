import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:voice_notes/database/daos/category_dao.dart';
import 'package:voice_notes/database/daos/note_dao.dart';
import 'package:voice_notes/database/daos/tag_dao.dart';
import 'package:voice_notes/database/models/note.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Notes, Categories, Tags, NoteTags],
  daos: [NoteDao, CategoryDao, TagDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Create default categories
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: 'Work',
            color: 0xFF4CAF50, // Green
            icon: 'work',
          ),
        );
        
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: 'Personal',
            color: 0xFF2196F3, // Blue
            icon: 'person',
          ),
        );
        
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: 'Ideas',
            color: 0xFFFFC107, // Amber
            icon: 'lightbulb',
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'voice_notes.sqlite'));
    return NativeDatabase(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  ref.onDispose(() {
    database.close();
  });
  
  return database;
});