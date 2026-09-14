// ============================================================
// STEP 1. 협진 상태
//
// 실제 Backend status enum은 GET API 500으로 아직 미확인.
// 아래 값은 UI DEMO 전용 상태입니다.
// ============================================================

enum ConsultationUiStatus { requested, inProgress, completed, withdrawn }

extension ConsultationUiStatusExtension on ConsultationUiStatus {
  String get label {
    switch (this) {
      case ConsultationUiStatus.requested:
        return '요청';
      case ConsultationUiStatus.inProgress:
        return '진행 중';
      case ConsultationUiStatus.completed:
        return '완료';
      case ConsultationUiStatus.withdrawn:
        return '철회';
    }
  }
}

// ============================================================
// STEP 2. 참여자
// POST /consultations/{id}/participants/
// doctor_id, role
// ============================================================

class ConsultationParticipantUiModel {
  final int id;
  final int doctorId;

  final String doctorName;
  final String department;

  // 실제 Backend role enum 미확인
  final String roleLabel;

  const ConsultationParticipantUiModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.roleLabel,
  });
}

// ============================================================
// STEP 3. 참조 자료
// POST /consultations/{id}/references/
// reference_type, reference_id
//
// 실제 reference_type enum은 아직 미확인.
// ============================================================

class ConsultationReferenceUiModel {
  final int id;

  final String referenceTypeLabel;
  final int referenceId;

  final String title;
  final String description;

  const ConsultationReferenceUiModel({
    required this.id,
    required this.referenceTypeLabel,
    required this.referenceId,
    required this.title,
    required this.description,
  });
}

// ============================================================
// STEP 4. 협진 의견
// POST /consultations/{id}/opinions/
// opinion_text, is_final
// ============================================================

class ConsultationOpinionUiModel {
  final int id;

  final int doctorId;
  final String doctorName;
  final String department;

  final String opinionText;
  final bool isFinal;

  final DateTime createdAt;

  const ConsultationOpinionUiModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.opinionText,
    required this.isFinal,
    required this.createdAt,
  });
}

// ============================================================
// STEP 5. 협진
// POST /api/consultations/ Request 구조 기반
// ============================================================

class ConsultationUiModel {
  final int id;

  final int patientId;
  final String patientName;
  final String patientMeta;

  final String subject;
  final String note;

  final int assignedDoctorId;
  final String assignedDoctorName;
  final String assignedDepartment;

  final int encounterId;

  final String priority;
  final DateTime dueAt;

  final ConsultationUiStatus status;

  final DateTime createdAt;

  final List<ConsultationParticipantUiModel> participants;
  final List<ConsultationReferenceUiModel> references;
  final List<ConsultationOpinionUiModel> opinions;

  final bool isDemo;

  const ConsultationUiModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientMeta,
    required this.subject,
    required this.note,
    required this.assignedDoctorId,
    required this.assignedDoctorName,
    required this.assignedDepartment,
    required this.encounterId,
    required this.priority,
    required this.dueAt,
    required this.status,
    required this.createdAt,
    required this.participants,
    required this.references,
    required this.opinions,
    this.isDemo = true,
  });

  ConsultationUiModel copyWith({ConsultationUiStatus? status}) {
    return ConsultationUiModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientMeta: patientMeta,
      subject: subject,
      note: note,
      assignedDoctorId: assignedDoctorId,
      assignedDoctorName: assignedDoctorName,
      assignedDepartment: assignedDepartment,
      encounterId: encounterId,
      priority: priority,
      dueAt: dueAt,
      status: status ?? this.status,
      createdAt: createdAt,
      participants: participants,
      references: references,
      opinions: opinions,
      isDemo: isDemo,
    );
  }
}
