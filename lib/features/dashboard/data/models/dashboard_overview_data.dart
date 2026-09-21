class DashboardOverviewData {
  final DashboardSummaryData summary;
  final DashboardAiStatusData aiStatus;
  final List<DashboardConsultationData> consultations;
  final List<DashboardWorkItemData> workItems;
  final int errorCount;

  const DashboardOverviewData({
    required this.summary,
    required this.aiStatus,
    required this.consultations,
    required this.workItems,
    required this.errorCount,
  });

  factory DashboardOverviewData.empty() {
    return const DashboardOverviewData(
      summary: DashboardSummaryData.empty,
      aiStatus: DashboardAiStatusData.empty,
      consultations: [],
      workItems: [],
      errorCount: 0,
    );
  }

  int get aiPendingRunningCount {
    return aiStatus.queued + aiStatus.running;
  }

  int get consultationReviewTodoCount {
    return workItems.where((item) {
      return item.workType == 'CONSULTATION_REVIEW' && item.status == 'TODO';
    }).length;
  }
}

class DashboardSummaryData {
  final String date;
  final int? departmentId;
  final int patientCount;
  final int examinationPendingCount;
  final int aiPendingCount;
  final int consultationPendingCount;
  final int signoffPendingCount;
  final int totalPendingCount;

  const DashboardSummaryData({
    required this.date,
    required this.departmentId,
    required this.patientCount,
    required this.examinationPendingCount,
    required this.aiPendingCount,
    required this.consultationPendingCount,
    required this.signoffPendingCount,
    required this.totalPendingCount,
  });

  static const empty = DashboardSummaryData(
    date: '',
    departmentId: null,
    patientCount: 0,
    examinationPendingCount: 0,
    aiPendingCount: 0,
    consultationPendingCount: 0,
    signoffPendingCount: 0,
    totalPendingCount: 0,
  );

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryData(
      date: json['date']?.toString() ?? '',
      departmentId: _nullableInt(json['department_id']),
      patientCount: _int(json['patient_count']),
      examinationPendingCount: _int(json['examination_pending_count']),
      aiPendingCount: _int(json['ai_pending_count']),
      consultationPendingCount: _int(json['consultation_pending_count']),
      signoffPendingCount: _int(json['signoff_pending_count']),
      totalPendingCount: _int(json['total_pending_count']),
    );
  }
}

class DashboardAiStatusData {
  final String date;
  final int queued;
  final int running;
  final int failed;
  final int completed;
  final int cancelled;
  final int total;

  const DashboardAiStatusData({
    required this.date,
    required this.queued,
    required this.running,
    required this.failed,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  static const empty = DashboardAiStatusData(
    date: '',
    queued: 0,
    running: 0,
    failed: 0,
    completed: 0,
    cancelled: 0,
    total: 0,
  );

  factory DashboardAiStatusData.fromJson(Map<String, dynamic> json) {
    return DashboardAiStatusData(
      date: json['date']?.toString() ?? '',
      queued: _int(json['queued']),
      running: _int(json['running']),
      failed: _int(json['failed']),
      completed: _int(json['completed']),
      cancelled: _int(json['cancelled']),
      total: _int(json['total']),
    );
  }
}

class DashboardConsultationData {
  final int id;
  final int patientId;
  final String patientName;
  final int requestedById;
  final int assignedDoctorId;
  final String subject;
  final String priority;
  final String status;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final int opinionCount;
  final bool hasResponse;

  const DashboardConsultationData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.requestedById,
    required this.assignedDoctorId,
    required this.subject,
    required this.priority,
    required this.status,
    required this.dueAt,
    required this.createdAt,
    required this.opinionCount,
    required this.hasResponse,
  });

  factory DashboardConsultationData.fromJson(Map<String, dynamic> json) {
    return DashboardConsultationData(
      id: _int(json['id']),
      patientId: _int(json['patient_id']),
      patientName: json['patient_name']?.toString() ?? '',
      requestedById: _int(json['requested_by_id']),
      assignedDoctorId: _int(json['assigned_doctor_id']),
      subject: json['subject']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dueAt: _dateTime(json['due_at']),
      createdAt: _dateTime(json['created_at']),
      opinionCount: _int(json['opinion_count']),
      hasResponse: json['has_response'] == true,
    );
  }
}

class DashboardWorkItemData {
  final int id;
  final int assignedUser;
  final int patient;
  final String workType;
  final String referenceType;
  final int referenceId;
  final String priority;
  final String status;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const DashboardWorkItemData({
    required this.id,
    required this.assignedUser,
    required this.patient,
    required this.workType,
    required this.referenceType,
    required this.referenceId,
    required this.priority,
    required this.status,
    required this.dueAt,
    required this.createdAt,
    required this.completedAt,
    required this.updatedAt,
  });

  factory DashboardWorkItemData.fromJson(Map<String, dynamic> json) {
    return DashboardWorkItemData(
      id: _int(json['id']),
      assignedUser: _int(json['assigned_user']),
      patient: _int(json['patient']),
      workType: json['work_type']?.toString() ?? '',
      referenceType: json['reference_type']?.toString() ?? '',
      referenceId: _int(json['reference_id']),
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dueAt: _dateTime(json['due_at']),
      createdAt: _dateTime(json['created_at']),
      completedAt: _dateTime(json['completed_at']),
      updatedAt: _dateTime(json['updated_at']),
    );
  }
}

int _int(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  return _int(value);
}

DateTime? _dateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
