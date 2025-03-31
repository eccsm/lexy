import 'package:drift/drift.dart';
import 'package:voice_notes/database/app_database.dart';
import 'package:voice_notes/database/models/note.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
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
  
  // Get note count by category
  Future<int> getNoteCountByCategory(int categoryId) async {
    final query = selectCount(db.notes)
      ..where((note) => note.categoryId.equals(categoryId));
    final result = await query.getSingle();
    return result;
  }
}