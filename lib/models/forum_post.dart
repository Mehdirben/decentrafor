class ForumPost {
  final String id;
  final String content;
  final String topicId;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentPostId;
  final int likesCount;
  final bool isEdited;
  final List<String> attachments;

  ForumPost({
    required this.id,
    required this.content,
    required this.topicId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.parentPostId,
    this.likesCount = 0,
    this.isEdited = false,
    this.attachments = const [],
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      content: json['content'],
      topicId: json['topic_id'],
      authorId: json['author_id'],
      authorName: json['author_name'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      parentPostId: json['parent_post_id'],
      likesCount: json['likes_count'] ?? 0,
      isEdited: json['is_edited'] ?? false,
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'topic_id': topicId,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'parent_post_id': parentPostId,
      'is_edited': isEdited,
      'attachments': attachments,
    };
  }

  bool get isReply => parentPostId != null;
}
