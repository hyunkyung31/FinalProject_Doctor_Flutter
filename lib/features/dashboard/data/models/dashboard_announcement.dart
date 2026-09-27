// ============================================================
// Dashboard Announcement
// GET /announcements/
// ============================================================

class DashboardAnnouncement {
  final int id;

  final String category;
  final String categoryLabel;

  final String title;
  final String body;

  final String priority;
  final String priorityLabel;

  final int? imageFileId;

  final String author;

  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  const DashboardAnnouncement({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.body,
    required this.priority,
    required this.priorityLabel,
    required this.imageFileId,
    required this.author,
    required this.publishedAt,
    required this.expiresAt,
    required this.updatedAt,
  });

  // ============================================================
  // JSON
  // ============================================================

  factory DashboardAnnouncement.fromJson(Map<String, dynamic> json) {
    return DashboardAnnouncement(
      id: _toInt(json['id']),
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      priorityLabel: json['priority_label']?.toString() ?? '',
      imageFileId: _toNullableInt(json['image_file_id']),
      author: json['author']?.toString() ?? '',
      publishedAt: _toDateTime(json['published_at']),
      expiresAt: _toDateTime(json['expires_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  bool get isImportant {
    return priority.trim().toUpperCase() == 'IMPORTANT';
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
