// lib/database/app_database.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'voice_notes.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        audio_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags(
        note_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes (id),
        FOREIGN KEY (tag_id) REFERENCES tags (id)
      )
    ''');

    // Create default categories
    await db.insert('categories', {
      'name': 'Work',
      'color': 0xFF4CAF50,
      'icon': 'work'
    });

    await db.insert('categories', {
      'name': 'Personal',
      'color': 0xFF2196F3,
      'icon': 'person'
    });

    await db.insert('categories', {
      'name': 'Ideas',
      'color': 0xFFFFC107,
      'icon': 'lightbulb'
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  ref.onDispose(() {
    database.close();
  });
  
  return database;
});