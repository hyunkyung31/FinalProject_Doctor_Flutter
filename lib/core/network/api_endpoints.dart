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

  static const String doctors = '/doctors/';

  static const String staffReauthenticate = '/staff/reauthenticate/';

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

  static const String staffAdminSchedules = '/staff/admin/schedules/';

  // ==========================================================
  // Staff Attendance Requests
  // ==========================================================

  static const String staffAttendanceRequests = '/staff/attendance-requests/';

  static String staffAttendanceRequestCancel(int requestId) {
    return '/staff/attendance-requests/$requestId/cancel/';
  }

  // ==========================================================
  // Staff Admin Attendance Requests
  // ==========================================================

  static const String staffAdminAttendanceRequests =
      '/staff/admin/attendance-requests/';

  static String staffAdminAttendanceRequestApprove(int requestId) {
    return '/staff/admin/attendance-requests/$requestId/approve/';
  }

  static String staffAdminAttendanceRequestReject(int requestId) {
    return '/staff/admin/attendance-requests/$requestId/reject/';
  }

  // ==========================================================
  // Leave Balance
  // ==========================================================

  static const String staffLeaveBalance = '/staff/leave-balance/';

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

  static String notificationRead(int recipientId) {
    return '/notifications/$recipientId/read/';
  }

  static const String notificationReadAll = '/notifications/read-all/';

  static const String notificationPreferences = '/notification-preferences/';

  static const String pushSubscriptions = '/push-subscriptions/';

  static String pushSubscriptionDetail(int subscriptionId) {
    return '/push-subscriptions/$subscriptionId/';
  }

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

  // ============================================================
  // AI
  // ============================================================

  static const String aiAnalyses = '/ai-analyses/';

  // ==========================================================
  // AI Analysis
  // ==========================================================

  static String aiAnalysisDetail(int analysisId) {
    return '/ai-analyses/$analysisId/';
  }

  static String aiAnalysisInputs(int analysisId) {
    return '/ai-analyses/$analysisId/inputs/';
  }

  static String aiAnalysisJobs(int analysisId) {
    return '/ai-analyses/$analysisId/jobs/';
  }

  // ==========================================================
  // Consultations
  // ==========================================================

  static const String consultations = '/consultations/';

  // ==========================================================
  // Dashboard
  // ==========================================================

  static const String dashboardSummary = '/dashboard/summary/';

  static const String dashboardAiStatus = '/dashboard/ai-status/';

  static const String dashboardConsultations = '/dashboard/consultations/';

  static const String dashboardWorkItems = '/dashboard/work-items/';
}
