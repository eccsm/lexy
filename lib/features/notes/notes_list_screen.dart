import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/note_card.dart';
import '../../shared/widgets/note_search_bar.dart';
import 'notes_controller.dart';


class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryFilter = ref.watch(selectedCategoryFilterProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Notes',
        showProfileButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: NoteSearchBar(
              onSearch: (term) => ref.read(searchTermProvider.notifier).state = term,
            ),
          ),
          
          // Category filter chips
          SizedBox(
            height: 48,
            child: categoriesAsync.when(
              data: (categories) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    // "All" filter
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategoryFilter == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(selectedCategoryFilterProvider.notifier).state = null;
                          }
                        },
                      ),
                    ),
                    
                    // Category filters
                    ...categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: selectedCategoryFilter == category.id,
                          backgroundColor: Color(category.color).withOpacity(0.1),
                          selectedColor: Color(category.color).withOpacity(0.3),
                          onSelected: (selected) {
                            ref.read(selectedCategoryFilterProvider.notifier).state = 
                              selected ? category.id : null;
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          
          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                // Filter notes by category if a filter is selected
                final filteredNotes = selectedCategoryFilter != null
                    ? notes.where((note) => note.note.categoryId == selectedCategoryFilter).toList()
                    : notes;
                
                if (filteredNotes.isEmpty) {
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
                          notes.isEmpty 
                              ? 'No notes yet. Start by recording one!'
                              : 'No notes in this category',
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
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => context.push('/notes/${note.note.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/record'),
        child: const Icon(Icons.mic),
      ),
    );
  }
}