class ApiNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final List<String> tags;
  
  ApiNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.tags = const [],
  });
  
  factory ApiNote.fromJson(Map<String, dynamic> json) {
    return ApiNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      categoryId: json['categoryId'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => tag as String)
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'categoryId': categoryId,
      'tags': tags,
    };
  }
}