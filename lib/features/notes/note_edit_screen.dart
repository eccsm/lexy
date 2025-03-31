import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'notes_controller.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String noteId;
  
  const NoteEditScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  // Initialize with null Value
  late Value<int?> _selectedCategoryId;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize with a default value
    _selectedCategoryId = const Value(null);
    _loadNote();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadNote() async {
    final noteWithCategory = await ref.read(
      noteProvider(widget.noteId).future,
    );
    
    if (mounted) {
      setState(() {
        _titleController.text = noteWithCategory.note.title;
        _contentController.text = noteWithCategory.note.content;
        // Safely handle the categoryId
        final categoryId = noteWithCategory.note.categoryId;
        _selectedCategoryId = categoryId != null ? Value(categoryId) : const Value(null);
      });
    }
  }
  
  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final noteWithCategory = await ref.read(
        noteProvider(widget.noteId).future,
      );
      
      final updatedNote = noteWithCategory.note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: Value(_selectedCategoryId.value),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      
      await ref.read(notesControllerProvider).updateNote(updatedNote);
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Note',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            // Category selector
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  value: _selectedCategoryId.value,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Category'),
                    ),
                    ...categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(category.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value != null ? Value(value) : const Value(null);
                    });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            
            // Content field
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 20,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
            
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: _isSaving ? null : _saveNote,
                text: 'Save Changes',
                isLoading: _isSaving,
                icon: Icons.save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}