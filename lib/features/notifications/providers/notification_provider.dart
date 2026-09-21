import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../data/models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient apiClient;

  NotificationProvider({required this.apiClient});

  List<NotificationItem> _notifications = [];

  int _unreadCount = 0;
  int _total = 0;

  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _unreadCount;

  int get total => _total;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': 1},
      );

      final data = response.data;

      if (data is! Map) {
        throw const FormatException('알림 목록 응답 형식이 올바르지 않습니다.');
      }

      final map = Map<String, dynamic>.from(data);

      final results = map['results'];

      if (results is! List) {
        throw const FormatException('알림 목록 results 형식이 올바르지 않습니다.');
      }

      _notifications = results
          .whereType<Map>()
          .map(
            (item) =>
                NotificationItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      _total = _toInt(map['total']);

      debugPrint(
        '[NOTIFICATION] 알림 목록 조회 완료: '
        '${_notifications.length}건 / total=$_total',
      );
    } catch (error) {
      _error = '알림 목록을 불러오지 못했습니다.';

      debugPrint('[NOTIFICATION] 알림 목록 조회 실패: $error');
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.notificationUnreadCount,
      );

      final data = response.data;

      if (data is! Map) {
        return;
      }

      final map = Map<String, dynamic>.from(data);

      _unreadCount = _toInt(map['unread_count']);

      debugPrint('[NOTIFICATION] 미읽음 알림: $_unreadCount건');

      notifyListeners();
    } catch (error) {
      debugPrint('[NOTIFICATION] 미읽음 개수 조회 실패: $error');
    }
  }

  Future<void> refresh() async {
    await Future.wait([loadNotifications(), loadUnreadCount()]);
  }

  Future<bool> markAsRead(NotificationItem item) async {
    if (item.isRead) {
      return true;
    }

    try {
      await apiClient.dio.post(ApiEndpoints.notificationRead(item.recipientId));

      final index = _notifications.indexWhere(
        (notification) => notification.recipientId == item.recipientId,
      );

      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }

      if (_unreadCount > 0) {
        _unreadCount--;
      }

      notifyListeners();

      debugPrint(
        '[NOTIFICATION] 읽음 처리 완료: '
        'recipientId=${item.recipientId}',
      );

      return true;
    } catch (error) {
      debugPrint('[NOTIFICATION] 읽음 처리 실패: $error');

      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await apiClient.dio.post(ApiEndpoints.notificationReadAll);

      _notifications = _notifications
          .map(
            (item) => item.copyWith(
              isRead: true,
              readAt: item.readAt ?? DateTime.now(),
            ),
          )
          .toList();

      _unreadCount = 0;

      notifyListeners();

      debugPrint('[NOTIFICATION] 전체 읽음 처리 완료');

      return true;
    } catch (error) {
      debugPrint('[NOTIFICATION] 전체 읽음 처리 실패: $error');

      return false;
    }
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
}
