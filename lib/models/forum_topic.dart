class ForumTopic {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int postsCount;
  final int viewsCount;
  final bool isPinned;
  final bool isLocked;
  final String? lastPostId;
  final String? lastPostAuthor;
  final DateTime? lastPostAt;

  ForumTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.postsCount = 0,
    this.viewsCount = 0,
    this.isPinned = false,
    this.isLocked = false,
    this.lastPostId,
    this.lastPostAuthor,
    this.lastPostAt,
  });

  factory ForumTopic.fromJson(Map<String, dynamic> json) {
    return ForumTopic(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      categoryId: json['category_id'],
      authorId: json['author_id'],
      authorName: json['author_name'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      postsCount: json['posts_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      isPinned: json['is_pinned'] ?? false,
      isLocked: json['is_locked'] ?? false,
      lastPostId: json['last_post_id'],
      lastPostAuthor: json['last_post_author'],
      lastPostAt: json['last_post_at'] != null ? DateTime.parse(json['last_post_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_pinned': isPinned,
      'is_locked': isLocked,
    };
  }
}
