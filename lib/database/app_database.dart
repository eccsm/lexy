import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// DAOs
import 'daos/category_dao.dart';
import 'daos/note_dao.dart';
import 'daos/tag_dao.dart';

import 'database_stub.dart';

import 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Notes,      // from schema.dart
    Categories, // from schema.dart
    Tags,
    NoteTags
  ],
  daos: [
    CategoryDao,
    TagDao,
    NoteDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // Create all tables from your new schema
          await m.createAll();

          // Then seed your initial data
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Work',
              color: const Value(Color(0xFF4CAF50)).hashCode,
              icon: const Value('work'),
            ),
          );

          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Personal',
              color: const Color(0xFF2196F3).toARGB32(),
              icon: const Value('person'),
            ),
          );

          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Ideas',
              color: const Color(0xFFFFC107).toARGB32(),
              icon: const Value('lightbulb'),
            ),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // For future schema changes
        },
      );

  @override
  CategoryDao get categoryDao => CategoryDao(this);
  @override
  TagDao get tagDao => TagDao(this);
  @override
  NoteDao get noteDao => NoteDao(this);

  // Existing custom queries

  Future<List<NoteWithCategory>> getAllNotesWithCategory() async {
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(notes.updatedAt)]);

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
    ])
      ..where(notes.id.equals(id));

    final row = await query.getSingle();

    return NoteWithCategory(
      note: row.readTable(notes),
      category: row.readTableOrNull(categories),
    );
  }

  Future<List<NoteWithCategory>> getNotesByCategory(int categoryId) async {
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ])
      ..where(notes.categoryId.equals(categoryId))
      ..orderBy([OrderingTerm.desc(notes.updatedAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);
      return NoteWithCategory(note: note, category: category);
    }).toList();
  }

  Future<List<Note>> searchNotes(String searchTerm) async {
    final term = '%$searchTerm%';
    return (select(notes)
      ..where((n) => n.title.like(term) | n.content.like(term))
    ).get();
  }

  Future<List<Note>> getUnsyncedNotes() async {
    return (select(notes)
      ..where((n) => n.isSynced.equals(false))
    ).get();
  }
}

// The platform-specific database connection is handled via the `database_stub.dart`
// The only requirement is that it returns a QueryExecutor via createExecutor()
QueryExecutor _openConnection() {
  final connection = createDatabaseConnection();
  return connection.createExecutor();
}

// For use in the UI layer
class NoteWithCategory {
  final Note note;
  final Category? category;

  NoteWithCategory({required this.note, this.category});
}

final databaseProvider = Provider<AppDatabase>((ref) {
  // Create the database instance here:
  return AppDatabase();
});
