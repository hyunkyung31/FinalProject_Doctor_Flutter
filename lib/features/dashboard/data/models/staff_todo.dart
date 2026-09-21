class StaffTodo {
  final int id;
  final int userId;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffTodo({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueAt,
    required this.completedAt,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffTodo.fromJson(Map<String, dynamic> json) {
    return StaffTodo(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      priority: json['priority']?.toString() ?? 'NORMAL',
      dueAt: _parseDateTime(json['due_at']),
      completedAt: _parseDateTime(json['completed_at']),
      description: json['description']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  bool get isHighPriority => priority.toUpperCase() == 'HIGH';

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(text);

    if (parsed == null) {
      return null;
    }

    final kst = parsed.toUtc().add(const Duration(hours: 9));

    return DateTime(
      kst.year,
      kst.month,
      kst.day,
      kst.hour,
      kst.minute,
      kst.second,
    );
  }
}
