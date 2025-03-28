import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_notes/features/notes/notes_controller.dart';
import 'package:voice_notes/shared/utils/date_formatter.dart';
import 'package:voice_notes/shared/widgets/app_bar.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Note Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editNote(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareNote(ref),
          ),
        ],
      ),
      body: noteAsync.when(
        data: (note) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note title
                Text(
                  note.title.isNotEmpty ? note.title : 'Untitled Note',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                const SizedBox(height: 8),
                
                // Date and category
                Row(
                  children: [
                    Text(
                      formatDate(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (note.category != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(note.category!.name),
                        backgroundColor: Color(note.category!.color),
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Note content
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 24),
                
                // Audio player (if available)
                if (note.audioPath != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playAudio(note.audioPath!),
                          ),
                          Expanded(
                            child: Slider(
                              value: 0,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text('0:00'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }
  
  void _editNote(BuildContext context) {
    // Navigation logic to edit screen
  }
  
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    // Show confirmation dialog
  }
  
  void _shareNote(WidgetRef ref) {
    // Share functionality
  }
  
  void _playAudio(String path) {
    // Audio playback logic
  }
}