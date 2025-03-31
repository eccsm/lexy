// File: lib/database/daos/category_dao.dart
import 'package:voicenotes/database/app_database.dart';
import 'package:voicenotes/database/models/note.dart';

part 'category_dao.g.dart';  // Note: this should point to the same folder

@DriftAccessor(tables: [Categories, Notes])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);
  
  // Get all categories
  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }
  
  // Get a single category by ID
  Future<Category> getCategoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }
  
  // Create a new category
  Future<int> createCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }
  
  // Update a category
  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }
  
  // Delete a category
  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }
  
  Future<int> getNoteCountByCategory(int categoryId) async {
  final query = select(notes)
    ..where((note) => note.categoryId.equals(categoryId));
  
  return query.get().asStream().length;
}
}