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

  static const String staffMe = '/auth/staff/me/';

  // ==========================================================
  // Staff Reservations
  // ==========================================================

  static const String staffReservations = '/staff/reservations/';

  static String staffReservationAccept(int reservationId) {
    return '/staff/reservations/$reservationId/accept/';
  }

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

  // ==========================================================
  // Patients
  // ==========================================================

  static const String patients = '/patients/';

  static String patientDetail(int patientId) {
    return '/patients/$patientId/';
  }

  static String patientIntegratedData(int patientId) {
    return '/patients/$patientId/integrated-data/';
  }

  static const String patientSearch = '/patients/search/';

  // ============================================================
  // Patient Timeline
  // ============================================================

  static String patientTimeline(int patientId) =>
      '/patients/$patientId/timeline';

  // ============================================================
  // Patient Recent View
  // ============================================================

  static const String staffRecentPatients = '/me/recent-patients/';

  static String patientView(int patientId) => '/patients/$patientId/view/';

  // ============================================================
  // Examinations
  // ============================================================

  static const String examinationTypes = '/examinations/types/';
  static const String examinationOrders = '/examinations/orders/';

  // ============================================================
  // Encounters
  // ============================================================

  static const String encounters = '/encounters/';
}
