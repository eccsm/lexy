import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Notes',
        showProfileButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: NoteSearchBar(
              onSearch: (term) => ref.read(searchTermProvider.notifier).state = term,
            ),
          ),
          
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('No notes yet. Start by recording one!'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => context.push('/notes/${note.id}'),
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