// ============================================================
// STEP 1. API Endpoints
// 실제 Swagger 기준
// ============================================================

class ApiEndpoints {
  ApiEndpoints._();

  // ==========================================================
  // Base URL
  // ==========================================================

  static const String baseUrl = 'https://api.34-50-57-207.sslip.io/api';

  // ==========================================================
  // Auth
  // ==========================================================

  static const String staffLogin = '/auth/staff/login/';

  static const String staffRefresh = '/auth/staff/refresh/';

  static const String staffMe = '/staff/me/';

  // ==========================================================
  // Work Items
  // ==========================================================

  static const String workItems = '/staff/work-items/';

  // ==========================================================
  // Staff Schedule
  // ==========================================================

  static const String staffSchedules = '/staff/schedules/';

  // ==========================================================
  // Todo
  // ==========================================================

  static const String todos = '/staff/todos/';

  // ==========================================================
  // Chat
  // ==========================================================

  static const String chatRooms = '/staff/chat-rooms/';

  // ==========================================================
  // Notifications
  // ==========================================================

  static const String notifications = '/notifications/';

  static const String notificationUnreadCount = '/notifications/unread-count/';
}
