// lib/database/daos/note_dao.dart
import '../app_database.dart';

class Note {
  final int id;
  final String title;
  final String content;
  final String? audioPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final int? categoryId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'audio_path': audioPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
      'category_id': categoryId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      audioPath: map['audio_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      categoryId: map['category_id'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final int color;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
    );
  }
}

class NoteWithCategory {
  final Note note;
  final Category? category;

  NoteWithCategory({
    required this.note,
    this.category,
  });
}

class NoteDao {
  final AppDatabase _db;

  NoteDao(this._db);

  Future<List<NoteWithCategory>> getAllNotesWithCategory() async {
    final db = await _db.database;
    
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT n.*, c.*
      FROM notes n
      LEFT JOIN categories c ON n.category_id = c.id
      ORDER BY n.updated_at DESC
    ''');
    
    return results.map((row) {
      final note = Note.fromMap({
        'id': row['id'],
        'title': row['title'],
        'content': row['content'],
        'audio_path': row['audio_path'],
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
        'is_synced': row['is_synced'],
        'category_id': row['category_id'],
      });
      
      Category? category;
      if (row['category_id'] != null) {
        category = Category.fromMap({
          'id': row['c.id'],
          'name': row['name'],
          'color': row['color'],
          'icon': row['icon'],
        });
      }
      
      return NoteWithCategory(note: note, category: category);
    }).toList();
  }

  Future<NoteWithCategory> getNoteWithCategory(int id) async {
    final db = await _db.database;
    
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT n.*, c.*
      FROM notes n
      LEFT JOIN categories c ON n.category_id = c.id
      WHERE n.id = ?
    ''', [id]);
    
    final row = results.first;
    
    final note = Note.fromMap({
      'id': row['id'],
      'title': row['title'],
      'content': row['content'],
      'audio_path': row['audio_path'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'is_synced': row['is_synced'],
      'category_id': row['category_id'],
    });
    
    Category? category;
    if (row['category_id'] != null) {
      category = Category.fromMap({
        'id': row['c.id'],
        'name': row['name'],
        'color': row['color'],
        'icon': row['icon'],
      });
    }
    
    return NoteWithCategory(note: note, category: category);
  }

  Future<int> insertNote(Note note) async {
    final db = await _db.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final db = await _db.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await _db.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}