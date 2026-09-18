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
  // STEP 4. Backend JSON → AppointmentUiModel
  // GET /api/staff/reservations/ 응답 기준
  // ============================================================

  factory AppointmentUiModel.fromJson(Map<String, dynamic> json) {
    return AppointmentUiModel(
      id: (json['id'] as num).toInt(),
      applicantName: json['applicant_name']?.toString() ?? '',
      applicantBirthDate: json['applicant_birth_date']?.toString() ?? '',
      applicantContact: json['applicant_contact']?.toString() ?? '',
      applicantGender: json['applicant_gender']?.toString(),
      reservedAt: _parseApiDateTime(json['reserved_at']),
      status: _parseStatus(json['status']?.toString() ?? ''),
      acceptedAt: _parseNullableDateTime(json['accepted_at']),
      createdAt: _parseApiDateTime(json['created_at']),
      updatedAt: _parseApiDateTime(json['updated_at']),
      canceledAt: _parseNullableDateTime(json['canceled_at']),
      cancelReason: json['cancel_reason']?.toString(),
      patientAccount: (json['patient_account'] as num?)?.toInt(),
      patient: (json['patient'] as num?)?.toInt(),
      doctor: (json['doctor'] as num?)?.toInt(),
      identityVerification: (json['identity_verification'] as num?)?.toInt(),
      department: (json['department'] as num?)?.toInt(),
      acceptedBy: (json['accepted_by'] as num?)?.toInt(),
      canceledBy: (json['canceled_by'] as num?)?.toInt(),
    );
  }

  // ============================================================
  // STEP 5. Backend Status 변환
  // ============================================================

  static AppointmentStatus _parseStatus(String value) {
    switch (value.toUpperCase()) {
      case 'REQUESTED':
        return AppointmentStatus.requested;

      case 'ACCEPTED':
        return AppointmentStatus.accepted;

      case 'CANCELED':
        return AppointmentStatus.canceled;

      default:
        throw FormatException('지원하지 않는 예약 상태입니다: $value');
    }
  }

  // ============================================================
  // STEP 6. Nullable DateTime 변환
  // ============================================================

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    return _parseApiDateTime(raw);
  }

  // ============================================================
  // STEP 7. 수정용 copyWith
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

  static DateTime _parseApiDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      throw const FormatException('예약 시간 값이 비어 있습니다.');
    }

    final hasTimezone =
        raw.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(raw);

    // timezone이 없으면 Backend 값은 UTC 기준으로 해석
    final normalized = hasTimezone ? raw : '${raw}Z';

    final utc = DateTime.parse(normalized).toUtc();

    // 기기 시간대와 무관하게 한국시간(KST, UTC+9) 적용
    final kst = utc.add(const Duration(hours: 9));

    // 이후 .toLocal()을 호출해도 시간이 다시 변하지 않도록
    // KST의 wall-clock 값을 local DateTime으로 생성
    return DateTime(
      kst.year,
      kst.month,
      kst.day,
      kst.hour,
      kst.minute,
      kst.second,
      kst.millisecond,
      kst.microsecond,
    );
  }

  // ============================================================
  // STEP 8. Gender 표시
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
  // STEP 9. 나이 계산
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
