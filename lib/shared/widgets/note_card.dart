import 'package:flutter/material.dart';

import '../../database/dao/note_dao.dart';
import '../utils/date_formatter.dart';


class NoteCard extends StatelessWidget {
  final NoteWithCategory note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = note.note.audioPath != null;
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and optional audio icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.note.title.isNotEmpty
                          ? note.note.title
                          : 'Untitled Note',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAudio)
                    const Icon(
                      Icons.audiotrack,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                note.note.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Bottom row with date and category
              Row(
                children: [
                  // Date
                  Text(
                    formatDate(note.note.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  
                  const Spacer(),
                  
                  // Category chip (if available)
                  if (note.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(note.category!.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.category!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(note.category!.color),
                        ),
                      ),
                    ),
                    
                  // Sync indicator
                  if (!note.note.isSynced)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.sync,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}