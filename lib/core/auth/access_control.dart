// ============================================================
// STEP 1. 의료진 사용자 Role 정의
// ============================================================

enum UserRole { doctor, nurse }

// ============================================================
// STEP 2. Role 표시 이름
// ============================================================

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.doctor:
        return '의사';

      case UserRole.nurse:
        return '간호사';
    }
  }
}

// ============================================================
// STEP 3. 시스템 Permission 정의
// ============================================================

enum AppPermission {
  // Dashboard
  dashboardView,

  // Patient
  patientView,
  patientEdit,
  patientEditVitals,

  // Appointment
  appointmentView,
  appointmentManage,

  // Examination
  examinationView,
  examinationOrder,
  examinationStatusUpdate,
  examinationConfirmResult,

  // Imaging
  imagingView,

  // AI
  aiView,
  aiRequest,
  aiReview,

  // CDSS
  cdssView,
  cdssApprove,

  // Consult
  consultView,
  consultManage,

  // Chat
  chatView,

  // Calendar
  calendarView,

  // Report
  reportView,
  reportApprove,

  // Prescription
  prescriptionCreate,
}

// ============================================================
// STEP 4. Role별 기본 Permission
// 추후 Backend/JWT 기반 권한으로 교체 가능
// ============================================================

class RolePermissions {
  static const Map<UserRole, Set<AppPermission>> defaults = {
    // --------------------------------------------------------
    // 의사
    // --------------------------------------------------------
    UserRole.doctor: {
      AppPermission.dashboardView,

      AppPermission.patientView,
      AppPermission.patientEdit,
      AppPermission.patientEditVitals,

      AppPermission.appointmentView,

      AppPermission.examinationView,
      AppPermission.examinationOrder,
      AppPermission.examinationStatusUpdate,
      AppPermission.examinationConfirmResult,

      AppPermission.imagingView,

      AppPermission.aiView,
      AppPermission.aiRequest,
      AppPermission.aiReview,

      AppPermission.cdssView,
      AppPermission.cdssApprove,

      AppPermission.consultView,
      AppPermission.consultManage,

      AppPermission.chatView,
      AppPermission.calendarView,

      AppPermission.reportView,
      AppPermission.reportApprove,

      AppPermission.prescriptionCreate,
    },

    // --------------------------------------------------------
    // 간호사
    // --------------------------------------------------------
    UserRole.nurse: {
      AppPermission.dashboardView,

      AppPermission.patientView,
      AppPermission.patientEditVitals,

      AppPermission.appointmentView,
      AppPermission.appointmentManage,

      AppPermission.examinationView,
      AppPermission.examinationStatusUpdate,

      AppPermission.imagingView,

      // AI / CDSS는 조회만 가능
      AppPermission.aiView,
      AppPermission.cdssView,

      AppPermission.consultView,

      AppPermission.chatView,
      AppPermission.calendarView,

      AppPermission.reportView,
    },
  };

  // ============================================================
  // STEP 5. 특정 Permission 보유 여부 확인
  // ============================================================

  static bool can(UserRole role, AppPermission permission) {
    return defaults[role]?.contains(permission) ?? false;
  }

  // ============================================================
  // STEP 6. Role이 가진 전체 Permission 반환
  // ============================================================

  static Set<AppPermission> permissionsOf(UserRole role) {
    return defaults[role] ?? {};
  }
}
