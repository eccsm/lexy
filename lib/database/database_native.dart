import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'database_stub.dart';

// Native implementation (Android, iOS, macOS, etc.)
class NativeDatabaseConnectionFactory implements DatabaseConnectionFactory {
  @override
  QueryExecutor createExecutor() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'voice_notes.db'));
      
      // Make sure the directory exists
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      
      // Set proper temp directory for SQLite
      final cacheDir = await getTemporaryDirectory();
      sqlite3.sqlite3.tempDirectory = cacheDir.path;
      
      return NativeDatabase.createInBackground(file);
    });
  }
}

// Factory function to create the appropriate database connection
DatabaseConnectionFactory createDatabaseConnection() {
  return NativeDatabaseConnectionFactory();
}