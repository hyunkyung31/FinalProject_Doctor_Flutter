import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

// ============================================================
// STEP 1. AI Analysis List Model
// ============================================================

class AiAnalysisRecord {
  final int id;
  final int examinationId;
  final int requestedBy;

  final String analysisType;
  final String status;

  final DateTime requestedAt;
  final DateTime? completedAt;

  const AiAnalysisRecord({
    required this.id,
    required this.examinationId,
    required this.requestedBy,
    required this.analysisType,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
  });

  factory AiAnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AiAnalysisRecord(
      id: _toInt(json['id']),
      examinationId: _toInt(json['examination']),
      requestedBy: _toInt(json['requested_by']),
      analysisType: json['analysis_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestedAt: DateTime.parse(json['requested_at'].toString()),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'].toString()),
    );
  }
}

// ============================================================
// STEP 2. AI Input Model
// ============================================================

class AiAnalysisInputRecord {
  final int id;
  final int analysisId;

  final String inputType;

  final int? examinationResultId;
  final int? imagingStudyId;
  final int? imagingSeriesId;
  final int? fileAssetId;

  final Map<String, dynamic> inputSnapshot;

  final String validationStatus;
  final String? validationMessage;

  final DateTime? createdAt;

  const AiAnalysisInputRecord({
    required this.id,
    required this.analysisId,
    required this.inputType,
    required this.examinationResultId,
    required this.imagingStudyId,
    required this.imagingSeriesId,
    required this.fileAssetId,
    required this.inputSnapshot,
    required this.validationStatus,
    required this.validationMessage,
    required this.createdAt,
  });

  factory AiAnalysisInputRecord.fromJson(Map<String, dynamic> json) {
    final snapshot = json['input_snapshot_json'];

    return AiAnalysisInputRecord(
      id: _toInt(json['id']),
      analysisId: _toInt(json['ai_analysis']),
      inputType: json['input_type']?.toString() ?? '',
      examinationResultId: _toNullableInt(json['examination_result']),
      imagingStudyId: _toNullableInt(json['imaging_study']),
      imagingSeriesId: _toNullableInt(json['imaging_series']),
      fileAssetId: _toNullableInt(json['file_asset']),
      inputSnapshot: snapshot is Map
          ? Map<String, dynamic>.from(snapshot)
          : const {},
      validationStatus: json['validation_status']?.toString() ?? '',
      validationMessage: json['validation_message']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

// ============================================================
// STEP 3. AI Job Model
// ============================================================

class AiAnalysisJobRecord {
  final int id;
  final int analysisId;
  final int aiModelVersion;

  final String status;

  final DateTime? queuedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  final String? errorCode;
  final String? errorMessage;

  final double progressPercent;

  final int retryCount;
  final int? retryOfJob;

  final DateTime? heartbeatAt;
  final String? workerId;

  const AiAnalysisJobRecord({
    required this.id,
    required this.analysisId,
    required this.aiModelVersion,
    required this.status,
    required this.queuedAt,
    required this.startedAt,
    required this.finishedAt,
    required this.errorCode,
    required this.errorMessage,
    required this.progressPercent,
    required this.retryCount,
    required this.retryOfJob,
    required this.heartbeatAt,
    required this.workerId,
  });

  factory AiAnalysisJobRecord.fromJson(Map<String, dynamic> json) {
    return AiAnalysisJobRecord(
      id: _toInt(json['id']),
      analysisId: _toInt(json['ai_analysis']),
      aiModelVersion: _toInt(json['ai_model_version']),
      status: json['status']?.toString() ?? '',
      queuedAt: _parseDateTime(json['queued_at']),
      startedAt: _parseDateTime(json['started_at']),
      finishedAt: _parseDateTime(json['finished_at']),
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      progressPercent: _toDouble(json['progress_percent']),
      retryCount: _toInt(json['retry_count']),
      retryOfJob: _toNullableInt(json['retry_of_job']),
      heartbeatAt: _parseDateTime(json['heartbeat_at']),
      workerId: json['worker_id']?.toString(),
    );
  }
}

// ============================================================
// STEP 4. AI Result Model
// ============================================================

class AiAnalysisResultRecord {
  final int id;
  final int jobId;

  final String resultType;
  final String summaryText;

  final double? confidence;

  final Map<String, dynamic> resultJson;

  final DateTime? generatedAt;
  final String status;

  const AiAnalysisResultRecord({
    required this.id,
    required this.jobId,
    required this.resultType,
    required this.summaryText,
    required this.confidence,
    required this.resultJson,
    required this.generatedAt,
    required this.status,
  });

  factory AiAnalysisResultRecord.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result_json'];

    return AiAnalysisResultRecord(
      id: _toInt(json['id']),
      jobId: _toInt(json['ai_analysis_job']),
      resultType: json['result_type']?.toString() ?? '',
      summaryText: json['summary_text']?.toString() ?? '',
      confidence: _toNullableDouble(json['confidence']),
      resultJson: resultJson is Map
          ? Map<String, dynamic>.from(resultJson)
          : const {},
      generatedAt: _parseDateTime(json['generated_at']),
      status: json['status']?.toString() ?? '',
    );
  }
}

// ============================================================
// AI Result Segmentation
// GET /api/ai-results/{resultId}/segmentations/
// ============================================================

class AiResultSegmentationRecord {
  final int id;
  final int aiAnalysisResultId;

  final String structureName;

  final int? maskFileAssetId;
  final int? meshFileAssetId;

  final double? volumeMm3;

  final Map<String, dynamic> metricsJson;

  final DateTime? generatedAt;

  const AiResultSegmentationRecord({
    required this.id,
    required this.aiAnalysisResultId,
    required this.structureName,
    required this.maskFileAssetId,
    required this.meshFileAssetId,
    required this.volumeMm3,
    required this.metricsJson,
    required this.generatedAt,
  });

  factory AiResultSegmentationRecord.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics_json'];

    return AiResultSegmentationRecord(
      id: _toInt(json['id']),
      aiAnalysisResultId: _toInt(json['ai_analysis_result']),
      structureName: json['structure_name']?.toString() ?? '',
      maskFileAssetId: _toNullableInt(json['mask_file_asset']),
      meshFileAssetId: _toNullableInt(json['mesh_file_asset']),
      volumeMm3: _toNullableDouble(json['volume_mm3']),
      metricsJson: metrics is Map
          ? Map<String, dynamic>.from(metrics)
          : const {},
      generatedAt: _parseDateTime(json['generated_at']),
    );
  }
}

// ============================================================
// STEP 5. AI Analysis Detail
// ============================================================

class AiAnalysisDetailRecord {
  final AiAnalysisRecord analysis;

  final List<AiAnalysisInputRecord> inputs;
  final List<AiAnalysisJobRecord> jobs;
  final List<AiAnalysisResultRecord> results;

  const AiAnalysisDetailRecord({
    required this.analysis,
    required this.inputs,
    required this.jobs,
    required this.results,
  });

  factory AiAnalysisDetailRecord.fromJson(Map<String, dynamic> json) {
    final analysisData = json['analysis'];

    if (analysisData is! Map) {
      throw const FormatException('AI 분석 상세 analysis 형식이 올바르지 않습니다.');
    }

    return AiAnalysisDetailRecord(
      analysis: AiAnalysisRecord.fromJson(
        Map<String, dynamic>.from(analysisData),
      ),
      inputs: _parseList(json['inputs'], AiAnalysisInputRecord.fromJson),
      jobs: _parseList(json['jobs'], AiAnalysisJobRecord.fromJson),
      results: _parseList(json['results'], AiAnalysisResultRecord.fromJson),
    );
  }
}

// ============================================================
// STEP. AI Analysis Patient Context
// Analysis → Examination → Order → Encounter → Patient
// ============================================================

class AiAnalysisPatientContextRecord {
  final int patientId;
  final int encounterId;

  final String name;
  final String birthDate;
  final String gender;

  const AiAnalysisPatientContextRecord({
    required this.patientId,
    required this.encounterId,
    required this.name,
    required this.birthDate,
    required this.gender,
  });
}

// ============================================================
// STEP. Clinical AI 자동 입력 데이터
// ============================================================

class ClinicalInputPrefillRecord {
  final AiAnalysisPatientContextRecord patient;
  final int? examinationResultId;
  final Map<String, dynamic> values;

  const ClinicalInputPrefillRecord({
    required this.patient,
    required this.examinationResultId,
    required this.values,
  });
}

// ============================================================
// STEP 6. AI Analysis Service
// ============================================================

class AiAnalysisService {
  final ApiClient apiClient;

  const AiAnalysisService({required this.apiClient});

  // ==========================================================
  // AI 분석 요청
  // POST /api/examinations/{examinationId}/ai-analyses/
  // ==========================================================

  Future<void> createAnalysis({
    required int examinationId,
    required String analysisType,
    required List<int> modelVersionIds,
    required List<Map<String, dynamic>> inputRefs,
  }) async {
    await apiClient.dio.post(
      '/examinations/$examinationId/ai-analyses/',
      data: {
        'analysis_type': analysisType,
        'model_version_ids': modelVersionIds,
        'input_refs': inputRefs,
      },
    );
  }

  // ==========================================================
  // 검사 최신 Result ID 조회
  // CLINICAL 분석 입력 연결용
  // ==========================================================

  Future<int?> fetchLatestExaminationResultId(int examinationId) async {
    final response = await apiClient.dio.get(
      '/examinations/$examinationId/results/',
    );

    if (response.data is! List) {
      throw const FormatException('검사 결과 목록 응답 형식이 올바르지 않습니다.');
    }

    final items = (response.data as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (items.isEmpty) {
      return null;
    }

    // version이 가장 큰 최신 결과 우선
    items.sort((a, b) {
      final aVersion = _toInt(a['version']);
      final bVersion = _toInt(b['version']);

      return bVersion.compareTo(aVersion);
    });

    final resultId = _toInt(items.first['id']);

    return resultId > 0 ? resultId : null;
  }

  // ==========================================================
  // 분석 목록
  // GET /api/ai-analyses/
  // ==========================================================

  Future<List<AiAnalysisRecord>> fetchAnalyses({
    int? patientId,
    String? status,
    String? type,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.aiAnalyses,
      queryParameters: {
        'patient_id': ?patientId,
        'status': ?status,
        'type': ?type,
      },
    );

    final rawList = _extractResponseList(response.data);

    return rawList.map(AiAnalysisRecord.fromJson).toList();
  }

  // ==========================================================
  // 분석 상세
  //
  // analysis + inputs + jobs + results
  // ==========================================================

  Future<AiAnalysisDetailRecord> fetchAnalysisDetail(int analysisId) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.aiAnalysisDetail(analysisId),
    );

    if (response.data is! Map) {
      throw const FormatException('AI 분석 상세 응답 형식이 올바르지 않습니다.');
    }

    return AiAnalysisDetailRecord.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ==========================================================
  // 입력 데이터
  // ==========================================================

  Future<List<AiAnalysisInputRecord>> fetchInputs(int analysisId) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.aiAnalysisInputs(analysisId),
    );

    return _extractResponseList(
      response.data,
    ).map(AiAnalysisInputRecord.fromJson).toList();
  }

  // ==========================================================
  // 작업 상태
  // ==========================================================

  Future<List<AiAnalysisJobRecord>> fetchJobs(int analysisId) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.aiAnalysisJobs(analysisId),
    );

    return _extractResponseList(
      response.data,
    ).map(AiAnalysisJobRecord.fromJson).toList();
  }

  // ==========================================================
  // 분석 연결 환자 조회
  //
  // Examination
  // → Order
  // → Encounter
  // → Patient
  // ==========================================================

  Future<AiAnalysisPatientContextRecord> fetchPatientContext(
    int examinationId,
  ) async {
    // ----------------------------------------------------------
    // 1. Examination
    // ----------------------------------------------------------

    final examinationResponse = await apiClient.dio.get(
      '/examinations/$examinationId/',
    );

    if (examinationResponse.data is! Map) {
      throw const FormatException('검사 상세 응답 형식이 올바르지 않습니다.');
    }

    final examination = Map<String, dynamic>.from(
      examinationResponse.data as Map,
    );

    final orderId = _toInt(examination['order']);

    if (orderId <= 0) {
      throw const FormatException('검사에 연결된 Order 정보가 없습니다.');
    }

    // ----------------------------------------------------------
    // 2. Examination Order
    // ----------------------------------------------------------

    final orderResponse = await apiClient.dio.get(
      '${ApiEndpoints.examinationOrders}$orderId/',
    );

    if (orderResponse.data is! Map) {
      throw const FormatException('검사 오더 응답 형식이 올바르지 않습니다.');
    }

    final order = Map<String, dynamic>.from(orderResponse.data as Map);

    final encounterId = _toInt(order['encounter']);

    if (encounterId <= 0) {
      throw const FormatException('검사 오더에 연결된 Encounter 정보가 없습니다.');
    }

    // ----------------------------------------------------------
    // 3. Encounter
    // ----------------------------------------------------------

    final encounterResponse = await apiClient.dio.get(
      '${ApiEndpoints.encounters}$encounterId/',
    );

    if (encounterResponse.data is! Map) {
      throw const FormatException('Encounter 응답 형식이 올바르지 않습니다.');
    }

    final encounter = Map<String, dynamic>.from(encounterResponse.data as Map);

    final patientId = _toInt(encounter['patient']);

    if (patientId <= 0) {
      throw const FormatException('Encounter에 연결된 Patient 정보가 없습니다.');
    }

    // ----------------------------------------------------------
    // 4. Patient
    // ----------------------------------------------------------

    final patientResponse = await apiClient.dio.get(
      ApiEndpoints.patientDetail(patientId),
    );

    if (patientResponse.data is! Map) {
      throw const FormatException('환자 상세 응답 형식이 올바르지 않습니다.');
    }

    final patient = Map<String, dynamic>.from(patientResponse.data as Map);

    return AiAnalysisPatientContextRecord(
      patientId: patientId,
      encounterId: encounterId,
      name: patient['name']?.toString() ?? '환자',
      birthDate: patient['birth_date']?.toString() ?? '',
      gender: patient['gender']?.toString() ?? '',
    );
  }

  // ==========================================================
  // Clinical AI 입력 자동 수집
  //
  // Patient       → Age / Sex
  // Vital Signs   → BP / PR / Weight / Length / BMI
  // MedicalHistory→ 일부 병력 양성값
  // Exam Result   → 혈액검사 / EF-TTE / Region RWMA
  // ==========================================================

  Future<ClinicalInputPrefillRecord> fetchClinicalInputPrefill(
    int examinationId,
  ) async {
    final patient = await fetchPatientContext(examinationId);

    final values = <String, dynamic>{};

    // ----------------------------------------------------------
    // 1. Patient
    // ----------------------------------------------------------

    final birthDate = DateTime.tryParse(patient.birthDate);

    if (birthDate != null) {
      final now = DateTime.now();

      var age = now.year - birthDate.year;

      final birthdayPassed =
          now.month > birthDate.month ||
          (now.month == birthDate.month && now.day >= birthDate.day);

      if (!birthdayPassed) {
        age -= 1;
      }

      values['Age'] = age;
    }

    switch (patient.gender.trim().toUpperCase()) {
      case 'M':
      case 'MALE':
        values['Sex'] = 1;
        break;

      case 'F':
      case 'FEMALE':
        values['Sex'] = 0;
        break;
    }

    // ----------------------------------------------------------
    // 2. Vital Signs
    // ----------------------------------------------------------

    final vitalResponse = await apiClient.dio.get(
      '/encounters/${patient.encounterId}/vital-signs/',
    );

    final vitals = _extractResponseList(vitalResponse.data);

    debugPrint(
      '[AI CLINICAL VITALS] '
      'encounterId=${patient.encounterId}, '
      'count=${vitals.length}, '
      'data=$vitals',
      wrapWidth: 1024,
    );

    if (vitals.isNotEmpty) {
      vitals.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['measured_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            DateTime.tryParse(b['measured_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      final latest = vitals.first;

      final systolic = _toNullableDouble(latest['systolic_bp']);

      final pulse = _toNullableDouble(latest['pulse_rate']);

      final height = _toNullableDouble(latest['height_cm']);

      final weight = _toNullableDouble(latest['weight_kg']);

      if (systolic != null) {
        values['BP'] = systolic;
      }

      if (pulse != null) {
        values['PR'] = pulse;
      }

      if (height != null) {
        values['Length'] = height;
      }

      if (weight != null) {
        values['Weight'] = weight;
      }

      if (height != null && height > 0 && weight != null && weight > 0) {
        final heightMeter = height / 100;

        values['BMI'] = double.parse(
          (weight / (heightMeter * heightMeter)).toStringAsFixed(2),
        );
      }
    }

    // ----------------------------------------------------------
    // 3. Medical History
    //
    // 기록이 존재하는 양성값만 1로 자동 입력한다.
    // 기록이 없다고 0으로 판단하지 않는다.
    // ----------------------------------------------------------

    final historyResponse = await apiClient.dio.get(
      '/patients/${patient.patientId}/medical-histories/',
    );

    final histories = _extractResponseList(historyResponse.data);

    debugPrint(
      '[AI CLINICAL HISTORIES] '
      'patientId=${patient.patientId}, '
      'count=${histories.length}, '
      'data=$histories',
      wrapWidth: 1024,
    );

    for (final history in histories) {
      final status = history['status']?.toString().toUpperCase() ?? '';

      if (status.isNotEmpty && status != 'ACTIVE') {
        continue;
      }

      final text = [
        history['condition_name'],
        history['condition_code'],
      ].whereType<Object>().join(' ').toUpperCase();

      if (_containsAny(text, ['당뇨', 'DIABETES', 'E10', 'E11', 'E13'])) {
        values['DM'] = 1;
      }

      if (_containsAny(text, ['고혈압', 'HYPERTENSION', 'I10'])) {
        values['HTN'] = 1;
      }

      if (_containsAny(text, [
        '만성 신부전',
        '만성신부전',
        'CHRONIC KIDNEY',
        'RENAL FAILURE',
        'N18',
      ])) {
        values['CRF'] = 1;
      }

      if (_containsAny(text, [
        '뇌혈관',
        '뇌졸중',
        'CEREBROVASCULAR',
        'STROKE',
        'I63',
        'I64',
      ])) {
        values['CVA'] = 1;
      }

      if (_containsAny(text, ['갑상선', 'THYROID'])) {
        values['Thyroid Disease'] = 1;
      }

      if (_containsAny(text, ['심부전', 'HEART FAILURE', 'I50'])) {
        values['CHF'] = 1;
      }

      if (_containsAny(text, [
        '이상지질',
        '고지혈',
        'DYSLIPID',
        'HYPERLIPID',
        'E78',
      ])) {
        values['DLP'] = 1;
      }

      if (_containsAny(text, ['비만', 'OBESITY', 'E66'])) {
        values['Obesity'] = 1;
      }

      if (_containsAny(text, [
        'ASTHMA',
        'COPD',
        '천식',
        '만성폐쇄성폐질환',
        'J44',
        'J45',
      ])) {
        values['Airway disease'] = 1;
      }
    }

    // ----------------------------------------------------------
    // 4. 최신 Examination Result
    // ----------------------------------------------------------

    final examinationResultId = await fetchLatestExaminationResultId(
      examinationId,
    );

    if (examinationResultId != null) {
      final resultResponse = await apiClient.dio.get(
        '/examinations/results/$examinationResultId/',
      );

      if (resultResponse.data is Map) {
        final resultDetail = Map<String, dynamic>.from(
          resultResponse.data as Map,
        );

        final rawMeasurements = resultDetail['measurements'];

        if (rawMeasurements is List) {
          for (final raw in rawMeasurements) {
            if (raw is! Map) {
              continue;
            }

            final measurement = Map<String, dynamic>.from(raw);

            final value = _toNullableDouble(measurement['value_numeric']);

            if (value == null) {
              continue;
            }

            final keys =
                [
                      measurement['code'],
                      measurement['name'],
                      measurement['display_name'],
                    ]
                    .whereType<Object>()
                    .map((item) => _normalizeClinicalName(item.toString()))
                    .where((item) => item.isNotEmpty)
                    .toSet();

            final field = _clinicalFieldForMeasurement(keys);

            if (field != null) {
              values[field] = value;
            }
          }
        }
      }
    }

    debugPrint(
      '[AI CLINICAL PREFILL] '
      'examinationId=$examinationId, '
      'patientId=${patient.patientId}, '
      'encounterId=${patient.encounterId}, '
      'resultId=$examinationResultId, '
      'filled=${values.length}/54',
    );

    debugPrint('[AI CLINICAL PREFILL DATA] $values', wrapWidth: 1024);

    return ClinicalInputPrefillRecord(
      patient: patient,
      examinationResultId: examinationResultId,
      values: values,
    );
  }

  // ==========================================================
  // AI 분석 재시도
  // POST /api/ai-analyses/{analysisId}/retry/
  // ==========================================================

  Future<void> retryAnalysis({
    required int analysisId,
    required List<int> failedJobIds,
  }) async {
    if (failedJobIds.isEmpty) {
      throw ArgumentError('재시도할 실패 Job이 없습니다.');
    }

    await apiClient.dio.post(
      '/ai-analyses/$analysisId/retry/',
      data: {'failed_job_ids': failedJobIds},
    );
  }

  // ==========================================================
  // AI 분석 취소
  // POST /api/ai-analyses/{analysisId}/cancel/
  // ==========================================================

  Future<void> cancelAnalysis({
    required int analysisId,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      throw ArgumentError('취소 사유를 입력해주세요.');
    }

    await apiClient.dio.post(
      '/ai-analyses/$analysisId/cancel/',
      data: {'reason': trimmedReason},
    );
  }

  // ==========================================================
  // AI Result Segmentation 조회
  // GET /api/ai-results/{resultId}/segmentations/
  // ==========================================================

  Future<List<AiResultSegmentationRecord>> fetchResultSegmentations(
    int resultId,
  ) async {
    final response = await apiClient.dio.get(
      '/ai-results/$resultId/segmentations/',
    );

    return _extractResponseList(
      response.data,
    ).map(AiResultSegmentationRecord.fromJson).toList();
  }
}

// ============================================================
// STEP 7. Parsing Helpers
// ============================================================

List<Map<String, dynamic>> _extractResponseList(dynamic data) {
  dynamic raw = data;

  if (data is Map && data['results'] is List) {
    raw = data['results'];
  }

  if (raw is! List) {
    throw const FormatException('AI 목록 응답 형식이 올바르지 않습니다.');
  }

  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) parser) {
  if (data is! List) {
    return <T>[];
  }

  return data
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

// ============================================================
// Clinical AI Helpers
// ============================================================

bool _containsAny(String source, List<String> keywords) {
  for (final keyword in keywords) {
    if (source.contains(keyword.toUpperCase())) {
      return true;
    }
  }

  return false;
}

String _normalizeClinicalName(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String? _clinicalFieldForMeasurement(Set<String> keys) {
  bool hasAny(List<String> aliases) {
    final normalizedAliases = aliases.map(_normalizeClinicalName).toSet();

    return keys.any(normalizedAliases.contains);
  }

  if (hasAny(['FBS', 'FASTING GLUCOSE', 'FASTING BLOOD SUGAR'])) {
    return 'FBS';
  }

  if (hasAny(['CR', 'CREATININE', 'CREA'])) {
    return 'CR';
  }

  if (hasAny(['TG', 'TRIGLYCERIDE', 'TRIGLYCERIDES'])) {
    return 'TG';
  }

  if (hasAny(['LDL'])) {
    return 'LDL';
  }

  if (hasAny(['HDL'])) {
    return 'HDL';
  }

  if (hasAny(['BUN'])) {
    return 'BUN';
  }

  if (hasAny(['ESR'])) {
    return 'ESR';
  }

  if (hasAny(['HB', 'HGB', 'HEMOGLOBIN'])) {
    return 'HB';
  }

  if (hasAny(['K', 'POTASSIUM'])) {
    return 'K';
  }

  if (hasAny(['NA', 'SODIUM'])) {
    return 'Na';
  }

  if (hasAny(['WBC'])) {
    return 'WBC';
  }

  if (hasAny(['LYMPH', 'LYMPHOCYTE', 'LYMPHOCYTES'])) {
    return 'Lymph';
  }

  if (hasAny(['NEUT', 'NEUTROPHIL', 'NEUTROPHILS'])) {
    return 'Neut';
  }

  if (hasAny(['PLT', 'PLATELET', 'PLATELETS'])) {
    return 'PLT';
  }

  if (hasAny(['EF-TTE', 'EFTTE', 'EJECTION FRACTION'])) {
    return 'EF-TTE';
  }

  if (hasAny(['REGION RWMA', 'REGIONRWMA', 'RWMA'])) {
    return 'Region RWMA';
  }

  return null;
}
