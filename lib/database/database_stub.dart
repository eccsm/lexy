// This stub conditionally exports either web or native implementation
import 'package:drift/drift.dart';

export 'database_web.dart' if (dart.library.ffi) 'database_native.dart';

// Simple interface that both implementations will provide
abstract class DatabaseConnectionFactory {
  QueryExecutor createExecutor();
}