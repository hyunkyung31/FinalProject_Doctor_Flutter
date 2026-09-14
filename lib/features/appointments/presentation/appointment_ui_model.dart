// ============================================================
// STEP 1. Appointment Status
// 실제 Backend 확인 상태:
// REQUESTED / ACCEPTED / CANCELED
// ============================================================

enum AppointmentStatus { requested, accepted, canceled }

// ============================================================
// STEP 2. Appointment Status Extension
// ============================================================

extension AppointmentStatusExtension on AppointmentStatus {
  String get serverValue {
    switch (this) {
      case AppointmentStatus.requested:
        return 'REQUESTED';

      case AppointmentStatus.accepted:
        return 'ACCEPTED';

      case AppointmentStatus.canceled:
        return 'CANCELED';
    }
  }

  String get label {
    switch (this) {
      case AppointmentStatus.requested:
        return '승인 대기';

      case AppointmentStatus.accepted:
        return '예약 승인';

      case AppointmentStatus.canceled:
        return '예약 취소';
    }
  }
}

// ============================================================
// STEP 3. Appointment UI Model
// 실제 /api/staff/reservations/ 응답 필드 기준
// ============================================================

class AppointmentUiModel {
  final int id;

  final String applicantName;
  final String applicantBirthDate;
  final String applicantContact;
  final String? applicantGender;

  final DateTime reservedAt;
  final AppointmentStatus status;

  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final DateTime? canceledAt;
  final String? cancelReason;

  final int? patientAccount;
  final int? patient;

  final int? doctor;
  final int? identityVerification;
  final int? department;

  final int? acceptedBy;
  final int? canceledBy;

  const AppointmentUiModel({
    required this.id,
    required this.applicantName,
    required this.applicantBirthDate,
    required this.applicantContact,
    required this.applicantGender,
    required this.reservedAt,
    required this.status,
    required this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.canceledAt,
    required this.cancelReason,
    required this.patientAccount,
    required this.patient,
    required this.doctor,
    required this.identityVerification,
    required this.department,
    required this.acceptedBy,
    required this.canceledBy,
  });

  // ============================================================
  // STEP 4. 수정용 copyWith
  // Mock 승인 처리 후 실제 API 연결 시에도 사용 가능
  // ============================================================

  AppointmentUiModel copyWith({
    AppointmentStatus? status,
    DateTime? acceptedAt,
    int? acceptedBy,
  }) {
    return AppointmentUiModel(
      id: id,
      applicantName: applicantName,
      applicantBirthDate: applicantBirthDate,
      applicantContact: applicantContact,
      applicantGender: applicantGender,
      reservedAt: reservedAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      canceledAt: canceledAt,
      cancelReason: cancelReason,
      patientAccount: patientAccount,
      patient: patient,
      doctor: doctor,
      identityVerification: identityVerification,
      department: department,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      canceledBy: canceledBy,
    );
  }

  // ============================================================
  // STEP 5. Gender 표시
  // ============================================================

  String get genderText {
    switch (applicantGender) {
      case 'MALE':
        return '남';

      case 'FEMALE':
        return '여';

      default:
        return '-';
    }
  }

  // ============================================================
  // STEP 6. 나이 계산
  // ============================================================

  int? get age {
    final birthDate = DateTime.tryParse(applicantBirthDate);

    if (birthDate == null) {
      return null;
    }

    final now = DateTime.now();

    var result = now.year - birthDate.year;

    final birthdayPassed =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);

    if (!birthdayPassed) {
      result -= 1;
    }

    return result;
  }
}
