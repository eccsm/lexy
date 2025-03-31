import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/database/app_database.dart';
import 'package:voice_notes/features/categories/category_dialog.dart';
import 'package:voice_notes/features/notes/notes_controller.dart';
import 'package:voice_notes/shared/widgets/app_bar.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Categories',
        showBackButton: true,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories yet. Create one!'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(context, ref, category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color),
          child: category.icon != null
              ? Icon(
                  _getIconData(category.icon!),
                  color: Colors.white,
                )
              : null,
        ),
        title: Text(category.name),
        subtitle: FutureBuilder<int>(
          future: ref.read(databaseProvider).categoryDao.getNoteCountByCategory(category.id),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Text('$count ${count == 1 ? 'note' : 'notes'}');
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCategoryDialog(context, ref, category),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteCategory(context, ref, category),
            ),
          ],
        ),
        onTap: () => context.push('/categories/${category.id}'),
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'person':
        return Icons.person;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'home':
        return Icons.home;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'directions_car':
        return Icons.directions_car;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.folder;
    }
  }
  
  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        onSave: (name, color, icon) async {
          final categoryDao = ref.read(databaseProvider).categoryDao;
          await categoryDao.createCategory(
            CategoriesCompanion.insert(
              name: name,
              color: color,
              icon: icon,
            ),
          );
          
          // Refresh categories
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }
  
  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        initialName: category.name,
        initialColor: category.color,
        initialIcon: category.icon,
        onSave: (name, color, icon) async {
          final categoryDao = ref.read(databaseProvider).categoryDao;
          await categoryDao.updateCategory(
            category.copyWith(
              name: name,
              color: color,
              icon: icon,
            ),
          );
          
          // Refresh categories
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }
  
  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? Notes in this category will not be deleted but will no longer be categorized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final categoryDao = ref.read(databaseProvider).categoryDao;
              await categoryDao.deleteCategory(category.id);
              
              // Refresh categories
              ref.invalidate(categoriesProvider);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}