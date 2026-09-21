// ============================================================
// STEP 1. 협진 상태
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
// STEP 2. 받은 협진 / 보낸 협진
// ============================================================

enum ConsultationUiDirection { received, sent }

extension ConsultationUiDirectionExtension on ConsultationUiDirection {
  String get label {
    switch (this) {
      case ConsultationUiDirection.received:
        return '받은 협진';
      case ConsultationUiDirection.sent:
        return '보낸 협진';
    }
  }

  String get shortLabel {
    switch (this) {
      case ConsultationUiDirection.received:
        return '받은';
      case ConsultationUiDirection.sent:
        return '보낸';
    }
  }
}

// ============================================================
// STEP 3. 참여자
// ============================================================

class ConsultationParticipantUiModel {
  final int id;
  final int doctorId;
  final String doctorName;
  final String department;
  final String roleLabel;
  final String? title;

  const ConsultationParticipantUiModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.roleLabel,
    this.title,
  });
}

// ============================================================
// STEP 4. 공유 자료
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
// STEP 5. 협진 의견
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
// STEP 6. 환자 추적검사 / 임상 요약
//
// /api/patients/{patient_id}/follow-up-records/ 응답을
// Flutter UI에 표시하기 위한 전용 모델입니다.
// ============================================================

class ConsultationFollowUpUiModel {
  final String medicalRecordNo;
  final String stageLabel;
  final int? encounterId;
  final DateTime? visitDate;
  final String? doctorName;
  final String? doctorDepartment;

  final int? cctaExaminationId;
  final DateTime? cctaPerformedAt;
  final String? cctaLocation;
  final String? cctaResultStatus;

  final List<ConsultationClinicalMetricUiModel> clinicalMetrics;

  const ConsultationFollowUpUiModel({
    required this.medicalRecordNo,
    required this.stageLabel,
    required this.encounterId,
    required this.visitDate,
    required this.doctorName,
    required this.doctorDepartment,
    required this.cctaExaminationId,
    required this.cctaPerformedAt,
    required this.cctaLocation,
    required this.cctaResultStatus,
    required this.clinicalMetrics,
  });
}

class ConsultationClinicalMetricUiModel {
  final String label;
  final String value;
  final String? unit;
  final String? flag;

  const ConsultationClinicalMetricUiModel({
    required this.label,
    required this.value,
    this.unit,
    this.flag,
  });
}

// ============================================================
// STEP 7. AI 결과 요약
//
// /api/ai-analyses/{analysis_id}/ 의 results[].result_json 기반
// - AI score는 협착률/보정 confidence가 아니므로 score로만 표시
// ============================================================

class ConsultationAiSummaryUiModel {
  final int analysisId;
  final int resultId;
  final String analysisType;
  final String resultStatus;

  final bool leftSignificantPositive;
  final double leftSignificantScore;

  final bool rightSignificantPositive;
  final double rightSignificantScore;

  final int seriesCount;
  final int frameCount;
  final String? warning;

  const ConsultationAiSummaryUiModel({
    required this.analysisId,
    required this.resultId,
    required this.analysisType,
    required this.resultStatus,
    required this.leftSignificantPositive,
    required this.leftSignificantScore,
    required this.rightSignificantPositive,
    required this.rightSignificantScore,
    required this.seriesCount,
    required this.frameCount,
    this.warning,
  });
}

// ============================================================
// STEP 8. 협진
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

  final int? encounterId;

  final String priority;
  final DateTime dueAt;

  final ConsultationUiStatus status;
  final ConsultationUiDirection direction;

  final DateTime createdAt;

  final List<ConsultationParticipantUiModel> participants;
  final List<ConsultationReferenceUiModel> references;
  final List<ConsultationOpinionUiModel> opinions;

  final ConsultationFollowUpUiModel? followUp;
  final ConsultationAiSummaryUiModel? aiSummary;

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
    required this.direction,
    required this.createdAt,
    required this.participants,
    required this.references,
    required this.opinions,
    this.followUp,
    this.aiSummary,
    this.isDemo = true,
  });

  ConsultationParticipantUiModel? get requester {
    for (final participant in participants) {
      if (participant.roleLabel.contains('요청')) {
        return participant;
      }
    }

    return participants.isEmpty ? null : participants.first;
  }

  String get priorityLabel {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return '긴급';
      case 'HIGH':
        return '높음';
      case 'LOW':
        return '낮음';
      default:
        return '일반';
    }
  }

  bool get canAccept {
    return direction == ConsultationUiDirection.received &&
        status == ConsultationUiStatus.requested;
  }

  bool get canWithdraw {
    return direction == ConsultationUiDirection.sent &&
        status == ConsultationUiStatus.requested;
  }

  bool get canComplete {
    return status == ConsultationUiStatus.inProgress;
  }

  bool get canWriteOpinion {
    return status == ConsultationUiStatus.inProgress;
  }

  bool get isReadOnly {
    return status == ConsultationUiStatus.completed ||
        status == ConsultationUiStatus.withdrawn;
  }

  ConsultationUiModel copyWith({
    ConsultationUiStatus? status,
    ConsultationUiDirection? direction,
    List<ConsultationParticipantUiModel>? participants,
    List<ConsultationReferenceUiModel>? references,
    List<ConsultationOpinionUiModel>? opinions,
    ConsultationFollowUpUiModel? followUp,
    ConsultationAiSummaryUiModel? aiSummary,
  }) {
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
      direction: direction ?? this.direction,
      createdAt: createdAt,
      participants: participants ?? this.participants,
      references: references ?? this.references,
      opinions: opinions ?? this.opinions,
      followUp: followUp ?? this.followUp,
      aiSummary: aiSummary ?? this.aiSummary,
      isDemo: isDemo,
    );
  }
}
