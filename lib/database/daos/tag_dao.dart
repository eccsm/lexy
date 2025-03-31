import 'package:drift/drift.dart';

import '../app_database.dart';
import '../models/note.dart';


part '../dao/tag_dao.g.dart';

@DriftAccessor(tables: [Tags, NoteTags, Notes])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(AppDatabase db) : super(db);
  
  // Get all tags
  Future<List<Tag>> getAllTags() {
    return select(tags).get();
  }
  
  // Get a single tag by ID
  Future<Tag> getTagById(int id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }
  
  // Create a new tag (if it doesn't exist) and return its ID
  Future<int> createTagIfNotExists(String name) async {
    final existingTag = await (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
    
    if (existingTag != null) {
      return existingTag.id;
    }
    
    return into(tags).insert(TagsCompanion.insert(name: name));
  }
  
  // Update a tag
  Future<bool> updateTag(Tag tag) {
    return update(tags).replace(tag);
  }
  
  // Delete a tag
  Future<int> deleteTag(int id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }
  
  // Get all tags for a note
  Future<List<Tag>> getTagsForNote(int noteId) {
    final query = select(tags).join([
      innerJoin(
        noteTags,
        noteTags.tagId.equalsExp(tags.id),
        useColumns: false,
      )
    ]);
    
    query.where(noteTags.noteId.equals(noteId));
    
    return query.map((row) => row.readTable(tags)).get();
  }
  
  // Add a tag to a note
  Future<void> addTagToNote(int noteId, int tagId) async {
    await into(noteTags).insert(
      NoteTagsCompanion.insert(
        noteId: noteId,
        tagId: tagId,
      ),
    );
  }
  
  // Remove a tag from a note
  Future<int> removeTagFromNote(int noteId, int tagId) {
    return (delete(noteTags)
      ..where((nt) => nt.noteId.equals(noteId) & nt.tagId.equals(tagId))
    ).go();
  }
  
  // Get notes by tag
  Future<List<Note>> getNotesByTag(int tagId) {
    final query = select(notes).join([
      innerJoin(
        noteTags,
        noteTags.noteId.equalsExp(notes.id),
        useColumns: false,
      )
    ]);
    
    query.where(noteTags.tagId.equals(tagId));
    
    return query.map((row) => row.readTable(notes)).get();
  }
}