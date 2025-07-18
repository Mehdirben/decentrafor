class ForumCategory {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final DateTime createdAt;
  final int topicsCount;
  final int postsCount;

  ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.createdAt,
    this.topicsCount = 0,
    this.postsCount = 0,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> json) {
    return ForumCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
      topicsCount: json['topics_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
