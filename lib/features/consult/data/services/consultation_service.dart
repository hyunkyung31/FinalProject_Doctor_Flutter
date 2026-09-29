import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

// ============================================================
// STEP 1. Consultation API Item
//
// GET /consultations/
// ConsultationRequestSerializer 응답 기준
// ============================================================

class ConsultationApiItem {
  final int id;

  final int patientId;
  final int? encounterId;

  final int requestedById;
  final Map<String, dynamic>? requestedByProfile;

  final int assignedDoctorId;
  final Map<String, dynamic>? assignedDoctorProfile;

  final String subject;
  final String requestNote;

  final String priority;
  final String status;

  final DateTime? dueAt;
  final DateTime? scheduledAt;

  final DateTime? acceptedAt;
  final DateTime? completedAt;

  final int? withdrawnBy;
  final DateTime? withdrawnAt;
  final String? withdrawReason;

  final DateTime createdAt;

  const ConsultationApiItem({
    required this.id,
    required this.patientId,
    required this.encounterId,
    required this.requestedById,
    required this.requestedByProfile,
    required this.assignedDoctorId,
    required this.assignedDoctorProfile,
    required this.subject,
    required this.requestNote,
    required this.priority,
    required this.status,
    required this.dueAt,
    required this.scheduledAt,
    required this.acceptedAt,
    required this.completedAt,
    required this.withdrawnBy,
    required this.withdrawnAt,
    required this.withdrawReason,
    required this.createdAt,
  });

  factory ConsultationApiItem.fromJson(Map<String, dynamic> json) {
    return ConsultationApiItem(
      id: _requiredInt(json['id'], 'id'),
      patientId: _requiredInt(json['patient'], 'patient'),
      encounterId: _nullableInt(json['encounter']),
      requestedById: _requiredInt(json['requested_by'], 'requested_by'),
      requestedByProfile: _nullableMap(json['requested_by_profile']),
      assignedDoctorId: _requiredInt(
        json['assigned_doctor'],
        'assigned_doctor',
      ),
      assignedDoctorProfile: _nullableMap(json['assigned_doctor_profile']),
      subject: json['subject']?.toString() ?? '',
      requestNote: json['request_note']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'NORMAL',
      status: json['status']?.toString() ?? '',
      dueAt: _dateTime(json['due_at']),
      scheduledAt: _dateTime(json['scheduled_at']),
      acceptedAt: _dateTime(json['accepted_at']),
      completedAt: _dateTime(json['completed_at']),
      withdrawnBy: _nullableInt(json['withdrawn_by']),
      withdrawnAt: _dateTime(json['withdrawn_at']),
      withdrawReason: json['withdraw_reason']?.toString(),
      createdAt:
          _dateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ============================================================
// STEP 2. Consultation Detail
//
// GET /consultations/{id}/
//
// {
//   consultation: {...},
//   participants: [...],
//   references: [...],
//   opinions: [...]
// }
// ============================================================

class ConsultationDetailApiResult {
  final ConsultationApiItem consultation;

  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> references;
  final List<Map<String, dynamic>> opinions;

  const ConsultationDetailApiResult({
    required this.consultation,
    required this.participants,
    required this.references,
    required this.opinions,
  });

  factory ConsultationDetailApiResult.fromJson(Map<String, dynamic> json) {
    final consultationData = json['consultation'];

    if (consultationData is! Map) {
      throw const FormatException('협진 상세 consultation 형식이 올바르지 않습니다.');
    }

    return ConsultationDetailApiResult(
      consultation: ConsultationApiItem.fromJson(
        Map<String, dynamic>.from(consultationData),
      ),
      participants: _mapList(json['participants'], 'participants'),
      references: _mapList(json['references'], 'references'),
      opinions: _mapList(json['opinions'], 'opinions'),
    );
  }
}

// ============================================================
// STEP 3. Consultation Service
// ============================================================

class ConsultationService {
  final ApiClient apiClient;

  ConsultationService({required this.apiClient});

  // ==========================================================
  // 협진 목록
  // GET /consultations/
  //
  // status
  // patient_id
  // assigned_to_me
  // ==========================================================

  Future<List<ConsultationApiItem>> fetchConsultations({
    String? status,
    int? patientId,
    bool assignedToMe = false,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    if (patientId != null) {
      queryParameters['patient_id'] = patientId;
    }

    if (assignedToMe) {
      queryParameters['assigned_to_me'] = true;
    }

    final response = await apiClient.dio.get(
      ApiEndpoints.consultations,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    if (response.data is! List) {
      throw const FormatException('협진 목록 응답 형식이 올바르지 않습니다.');
    }

    final result = <ConsultationApiItem>[];

    for (final item in response.data as List) {
      if (item is! Map) {
        continue;
      }

      result.add(ConsultationApiItem.fromJson(Map<String, dynamic>.from(item)));
    }

    return result;
  }

  // ==========================================================
  // 협진 상세
  // GET /consultations/{id}/
  // ==========================================================

  Future<ConsultationDetailApiResult> fetchConsultationDetail(
    int consultationId,
  ) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.consultationDetail(consultationId),
    );

    if (response.data is! Map) {
      throw const FormatException('협진 상세 응답 형식이 올바르지 않습니다.');
    }

    return ConsultationDetailApiResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ==========================================================
  // 협진 요청
  // POST /consultations/
  // ==========================================================

  Future<ConsultationDetailApiResult> createConsultation({
    required int patientId,
    required String subject,
    required String note,
    required int assignedDoctorId,
    int? encounterId,
    String priority = 'NORMAL',
    DateTime? dueAt,
  }) async {
    final body = <String, dynamic>{
      'patient_id': patientId,
      'subject': subject,
      'note': note,
      'assigned_doctor_id': assignedDoctorId,
      'priority': priority,
    };

    if (encounterId != null) {
      body['encounter_id'] = encounterId;
    }

    if (dueAt != null) {
      body['due_at'] = dueAt.toIso8601String();
    }

    final response = await apiClient.dio.post(
      ApiEndpoints.consultations,
      data: body,
    );

    if (response.data is! Map) {
      throw const FormatException('협진 요청 응답 형식이 올바르지 않습니다.');
    }

    return ConsultationDetailApiResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ==========================================================
  // 협진 수락
  // POST /consultations/{id}/accept/
  // ==========================================================

  Future<ConsultationDetailApiResult> acceptConsultation(
    int consultationId,
  ) async {
    await apiClient.dio.post(ApiEndpoints.consultationAccept(consultationId));

    return fetchConsultationDetail(consultationId);
  }

  // ==========================================================
  // 협진 완료
  // POST /consultations/{id}/complete/
  // ==========================================================

  Future<ConsultationDetailApiResult> completeConsultation(
    int consultationId,
  ) async {
    await apiClient.dio.post(ApiEndpoints.consultationComplete(consultationId));

    return fetchConsultationDetail(consultationId);
  }

  // ==========================================================
  // 협진 회수
  // POST /consultations/{id}/withdraw/
  // ==========================================================

  Future<ConsultationDetailApiResult> withdrawConsultation({
    required int consultationId,
    required String reason,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.consultationWithdraw(consultationId),
      data: {'reason': reason},
    );

    return fetchConsultationDetail(consultationId);
  }

  // ==========================================================
  // 협진 의견 작성
  // POST /consultations/{id}/opinions/
  // ==========================================================

  Future<ConsultationDetailApiResult> addOpinion({
    required int consultationId,
    required String opinionText,
    bool isFinal = false,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.consultationOpinions(consultationId),
      data: {'opinion_text': opinionText, 'is_final': isFinal},
    );

    return fetchConsultationDetail(consultationId);
  }
}

// ============================================================
// STEP 4. Parsers
// ============================================================

int _requiredInt(dynamic value, String fieldName) {
  if (value is num) {
    return value.toInt();
  }

  final parsed = int.tryParse(value?.toString() ?? '');

  if (parsed == null) {
    throw FormatException('협진 응답의 $fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

DateTime? _dateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

Map<String, dynamic>? _nullableMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _mapList(dynamic value, String fieldName) {
  if (value == null) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('협진 상세 $fieldName 형식이 올바르지 않습니다.');
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
