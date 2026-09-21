class NotificationItem {
  final int recipientId;
  final int notificationId;
  final String notificationType;
  final String title;
  final String body;
  final String referenceType;
  final int? referenceId;
  final String priority;
  final DateTime notificationCreatedAt;
  final String deliveryStatus;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  final DateTime recipientCreatedAt;

  const NotificationItem({
    required this.recipientId,
    required this.notificationId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.referenceType,
    required this.referenceId,
    required this.priority,
    required this.notificationCreatedAt,
    required this.deliveryStatus,
    required this.isRead,
    required this.readAt,
    required this.deliveredAt,
    required this.failureReason,
    required this.recipientCreatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final notificationRaw = json['notification'];

    final notification = notificationRaw is Map
        ? Map<String, dynamic>.from(notificationRaw)
        : <String, dynamic>{};

    return NotificationItem(
      recipientId: _toInt(json['id']),
      notificationId: _toInt(notification['id']),
      notificationType: notification['notification_type']?.toString() ?? '',
      title: notification['title']?.toString() ?? '',
      body: notification['body']?.toString() ?? '',
      referenceType: notification['reference_type']?.toString() ?? '',
      referenceId: _toNullableInt(notification['reference_id']),
      priority: notification['priority']?.toString() ?? 'NORMAL',
      notificationCreatedAt: _toDateTime(notification['created_at']),
      deliveryStatus: json['delivery_status']?.toString() ?? '',
      isRead: json['is_read'] == true,
      readAt: _toNullableDateTime(json['read_at']),
      deliveredAt: _toNullableDateTime(json['delivered_at']),
      failureReason: json['failure_reason']?.toString(),
      recipientCreatedAt: _toDateTime(json['created_at']),
    );
  }

  NotificationItem copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationItem(
      recipientId: recipientId,
      notificationId: notificationId,
      notificationType: notificationType,
      title: title,
      body: body,
      referenceType: referenceType,
      referenceId: referenceId,
      priority: priority,
      notificationCreatedAt: notificationCreatedAt,
      deliveryStatus: deliveryStatus,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt,
      failureReason: failureReason,
      recipientCreatedAt: recipientCreatedAt,
    );
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

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
