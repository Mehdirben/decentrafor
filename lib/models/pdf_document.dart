class PdfDocument {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final String category;
  final List<String> tags;

  PdfDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    required this.category,
    required this.tags,
  });

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      fileName: json['file_name'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      thumbnailUrl: json['thumbnail_url'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'tags': tags,
    };
  }

  // Helper method to format file size
  String get sizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
