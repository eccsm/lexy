import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicenotes/features/notes/notes_controller.dart';
import 'package:voicenotes/shared/utils/date_formatter.dart';
import 'package:voicenotes/shared/widgets/app_bar.dart';

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
            onPressed: () => _shareNote(context, ref),
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
                  note.note.title.isNotEmpty ? note.note.title : 'Untitled Note',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                const SizedBox(height: 8),
                
                // Date and category
                Row(
                  children: [
                    Text(
                      formatDate(note.note.createdAt),
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
                  note.note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 24),
                
                // Audio player (if available)
                if (note.note.audioPath != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playAudio(context, note.note.audioPath!),
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
    context.push('/notes/$noteId/edit');
  }
  
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await ref.read(notesControllerProvider).deleteNote(int.parse(noteId));
                if (context.mounted) {
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting note: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _shareNote(BuildContext context, WidgetRef ref) async {
    try {
      final note = await ref.read(noteProvider(noteId).future);
      
      final content = '${note.note.title}\n\n${note.note.content}';
      
      // Using the share package
      // Share.share(content, subject: note.note.title);
      
      // For now, just show a placeholder
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing functionality will be implemented here'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _playAudio(BuildContext context, String path) async {
    try {
      // Here you would use the flutter_sound player to play the audio
      // For example:
      // final player = FlutterSoundPlayer();
      // await player.openPlayer();
      // await player.startPlayer(fromURI: path);
      
      // For now, just show a placeholder
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playback will be implemented here'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}