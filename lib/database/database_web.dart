import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:logger/logger.dart';

import 'database_stub.dart';


final Logger _logger = Logger();

// Web-specific implementation
class WebDatabaseConnectionFactory implements DatabaseConnectionFactory {
  @override
  QueryExecutor createExecutor() {
    return DatabaseConnection.delayed(Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'voice_notes_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        _logger.e('Using ${result.chosenImplementation} due to missing features: ${result.missingFeatures}');
      }

      return result.resolvedExecutor;
    }));
  }
}

// Factory function to create the appropriate database connection
DatabaseConnectionFactory createDatabaseConnection() {
  return WebDatabaseConnectionFactory();
}