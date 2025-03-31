import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/features/notes/notes_controller.dart';
import 'package:voice_notes/shared/widgets/app_bar.dart';
import 'package:voice_notes/shared/widgets/note_card.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final int categoryId;
  
  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(
      FutureProvider((ref) {
        final database = ref.watch(databaseProvider);
        return database.categoryDao.getCategoryById(categoryId);
      }),
    );
    
    final notesAsync = ref.watch(notesByCategoryProvider(categoryId));
    
    return Scaffold(
      appBar: CustomAppBar(
        title: categoryAsync.when(
          data: (category) => category.name,
          loading: () => 'Loading...',
          error: (_, __) => 'Category',
        ),
        showBackButton: true,
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes in this category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => context.push('/notes/${note.note.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }
}