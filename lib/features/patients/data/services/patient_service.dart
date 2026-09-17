import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../presentation/widgets/patient_detail_tabs.dart';

// ============================================================
// Patient Page Result | Pagination 응답 모델
// ============================================================

class PatientPageResult {
  final List<PatientUiModel> patients;
  final int count;
  final String? next;
  final String? previous;

  const PatientPageResult({
    required this.patients,
    required this.count,
    required this.next,
    required this.previous,
  });

  bool get hasNext => next != null;

  bool get hasPrevious => previous != null;
}

class ExaminationResultSummary {
  final int id;
  final String resultType;
  final int version;
  final DateTime? collectedAt;
  final String status;
  final int? examinationId;
  final DateTime? confirmedAt;

  const ExaminationResultSummary({
    required this.id,
    required this.resultType,
    required this.version,
    required this.collectedAt,
    required this.status,
    required this.examinationId,
    required this.confirmedAt,
  });

  factory ExaminationResultSummary.fromJson(Map<String, dynamic> json) {
    return ExaminationResultSummary(
      id: _parseInt(json['id']) ?? 0,
      resultType: json['result_type']?.toString() ?? '',
      version: _parseInt(json['version']) ?? 1,
      collectedAt: DateTime.tryParse(json['collected_at']?.toString() ?? ''),
      status: json['status']?.toString().toUpperCase() ?? '',
      examinationId: _parseInt(json['examination']),
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class ExaminationResultDetail {
  final ExaminationResultSummary result;
  final List<PatientLabMeasurement> measurements;

  const ExaminationResultDetail({
    required this.result,
    required this.measurements,
  });

  factory ExaminationResultDetail.fromJson(Map<String, dynamic> json) {
    final resultData = json['result'];

    if (resultData is! Map) {
      throw const FormatException('검사 결과 상세 result 형식이 올바르지 않습니다.');
    }

    final measurementData = json['measurements'];

    final measurements = measurementData is List
        ? measurementData
              .whereType<Map>()
              .map(
                (item) => PatientLabMeasurement.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <PatientLabMeasurement>[];

    return ExaminationResultDetail(
      result: ExaminationResultSummary.fromJson(
        Map<String, dynamic>.from(resultData),
      ),
      measurements: measurements,
    );
  }
}

// ============================================================
// Patient Service : 실제 Patient API 연결
// ============================================================

class PatientService {
  final ApiClient apiClient;

  PatientService({required this.apiClient});

  // ==========================================================
  // 환자 목록 조회
  // GET /patients/
  // ==========================================================

  Future<List<PatientUiModel>> fetchPatients() async {
    final result = await fetchPatientPage();

    return result.patients;
  }

  // ==========================================================
  // 환자 목록 Pagination 조회
  // GET /patients/?page={page}
  // ==========================================================

  Future<PatientPageResult> fetchPatientPage({int page = 1}) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.patients,
      queryParameters: {'page': page},
    );

    return _parsePatientPageResponse(response.data, responseName: '환자 목록');
  }

  // ==========================================================
  // 내 담당 환자 목록
  // GET /patients/?assigned_to_me=true
  // ==========================================================

  Future<PatientPageResult> fetchAssignedPatientPage({int page = 1}) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.patients,
      queryParameters: {'assigned_to_me': true, 'page': page},
    );

    return _parsePatientPageResponse(response.data, responseName: '담당 환자 목록');
  }

  // ==========================================================
  // 생년월일 기반 환자 필터
  // GET /patients/?birth_date=YYYY-MM-DD
  // ==========================================================

  Future<PatientPageResult> fetchPatientsByBirthDate({
    required String birthDate,
    int page = 1,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.patients,
      queryParameters: {'birth_date': birthDate, 'page': page},
    );

    return _parsePatientPageResponse(response.data, responseName: '생년월일 환자 목록');
  }

  // ==========================================================
  // 환자 검색
  // GET /patients/search/?q={query}
  // ==========================================================

  Future<List<PatientUiModel>> searchPatients(String query) async {
    final result = await searchPatientPage(query);

    return result.patients;
  }

  // ==========================================================
  // STEP 6. 환자 검색 Pagination 조회
  // GET /patients/search/?q={query}&page={page}
  // ==========================================================

  Future<PatientPageResult> searchPatientPage(
    String query, {
    int page = 1,
  }) async {
    final normalizedQuery = query.trim();

    // 검색어가 비어 있으면 기본 환자 목록 조회
    if (normalizedQuery.isEmpty) {
      return fetchPatientPage(page: page);
    }

    final response = await apiClient.dio.get(
      ApiEndpoints.patientSearch,
      queryParameters: {'q': normalizedQuery, 'page': page},
    );

    return _parsePatientPageResponse(response.data, responseName: '환자 검색');
  }

  // ==========================================================
  // STEP 7. Pagination 응답 파싱
  // count / next / previous / results
  // ==========================================================

  PatientPageResult _parsePatientPageResponse(
    dynamic responseData, {
    required String responseName,
  }) {
    if (responseData is! Map) {
      throw FormatException('$responseName 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(responseData);

    final results = data['results'];

    if (results is! List) {
      throw FormatException('$responseName results 형식이 올바르지 않습니다.');
    }

    final patients = results.map((item) {
      if (item is! Map) {
        throw FormatException('$responseName 환자 데이터 형식이 올바르지 않습니다.');
      }

      return PatientUiModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    final countData = data['count'];

    final count = countData is num
        ? countData.toInt()
        : int.tryParse(countData?.toString() ?? '') ?? patients.length;

    final next = data['next']?.toString();
    final previous = data['previous']?.toString();

    return PatientPageResult(
      patients: patients,
      count: count,
      next: next,
      previous: previous,
    );
  }

  // ==========================================================
  // 환자 조회 기록
  // POST /patients/{patientId}/view/
  // 최근 조회 환자 및 감사기록 갱신
  // ==========================================================

  Future<void> recordPatientView(int patientId) async {
    await apiClient.dio.post(ApiEndpoints.patientView(patientId));
  }

  // ==========================================================
  // 최근 조회 환자 목록
  // GET /me/recent-patients/
  // ==========================================================

  Future<PatientPageResult> fetchRecentPatients({int page = 1}) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.staffRecentPatients,
      queryParameters: {'page': page},
    );

    if (response.data is! Map) {
      throw const FormatException('최근 조회 환자 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final results = data['results'];

    if (results is! List) {
      throw const FormatException('최근 조회 환자 results 형식이 올바르지 않습니다.');
    }

    final patients = <PatientUiModel>[];

    for (final item in results) {
      if (item is! Map) {
        continue;
      }

      final recentItem = Map<String, dynamic>.from(item);

      final patientData = recentItem['patient'];

      if (patientData is! Map) {
        continue;
      }

      patients.add(
        PatientUiModel.fromJson(Map<String, dynamic>.from(patientData)),
      );
    }

    final countData = data['count'];

    final count = countData is num
        ? countData.toInt()
        : int.tryParse(countData?.toString() ?? '') ?? patients.length;

    return PatientPageResult(
      patients: patients,
      count: count,
      next: data['next']?.toString(),
      previous: data['previous']?.toString(),
    );
  }

  // ==========================================================
  // 환자 Timeline 조회
  // GET /patients/{patientId}/timeline/
  // date: YYYY-MM-DD
  // type: ENCOUNTER | EXAMINATION | AI_ANALYSIS | REPORT
  // ==========================================================

  Future<List<PatientTimelineItem>> fetchPatientTimeline(
    int patientId, {
    String? date,
    String? type,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (date != null && date.trim().isNotEmpty) {
      queryParameters['date'] = date.trim();
    }

    if (type != null && type.trim().isNotEmpty) {
      queryParameters['type'] = type.trim();
    }

    final response = await apiClient.dio.get(
      ApiEndpoints.patientTimeline(patientId),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    if (response.data is! Map) {
      throw const FormatException('환자 Timeline 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final results = data['results'];

    if (results is! List) {
      throw const FormatException('환자 Timeline results 형식이 올바르지 않습니다.');
    }

    return results.map((item) {
      if (item is! Map) {
        throw const FormatException('환자 Timeline 항목 형식이 올바르지 않습니다.');
      }

      return PatientTimelineItem.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<List<ExaminationResultSummary>> fetchExaminationResults(
    int examinationId,
  ) async {
    final response = await apiClient.dio.get(
      '/examinations/$examinationId/results/',
    );

    if (response.data is! List) {
      throw const FormatException('검사 결과 목록 응답 형식이 올바르지 않습니다.');
    }

    final results = (response.data as List)
        .whereType<Map>()
        .map(
          (item) => ExaminationResultSummary.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    results.sort((a, b) => b.version.compareTo(a.version));

    return results;
  }

  Future<ExaminationResultDetail> fetchExaminationResultDetail(
    int resultId,
  ) async {
    final response = await apiClient.dio.get(
      '/examinations/results/$resultId/',
    );

    if (response.data is! Map) {
      throw const FormatException('검사 결과 상세 응답 형식이 올바르지 않습니다.');
    }

    return ExaminationResultDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ==========================================================
  // STEP 8. 환자 통합 데이터 조회
  // GET /patients/{patientId}/integrated-data/
  // 담당 진료과 / 담당 의사 / 검사 데이터 연결
  // ==========================================================

  Future<PatientUiModel> fetchIntegratedPatient(PatientUiModel patient) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.patientIntegratedData(patient.patientId),
    );

    if (response.data is! Map) {
      throw const FormatException('환자 통합 데이터 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final careTeam = data['care_team'];

    String? department;
    String? doctorName;

    if (careTeam is List) {
      for (final item in careTeam) {
        if (item is! Map) {
          continue;
        }

        final member = Map<String, dynamic>.from(item);

        final staffRole = member['staff_role']?.toString().toUpperCase();

        final isActive = member['is_active'] == true;

        if (staffRole != 'DOCTOR' || !isActive) {
          continue;
        }

        final doctorData = member['doctor'];

        if (doctorData is! Map) {
          continue;
        }

        final doctor = Map<String, dynamic>.from(doctorData);

        final name = doctor['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          doctorName = '$name 의사';
        }

        final departmentData = doctor['department'];

        if (departmentData is Map) {
          final departmentMap = Map<String, dynamic>.from(departmentData);

          final departmentName = departmentMap['name']?.toString().trim();

          if (departmentName != null && departmentName.isNotEmpty) {
            department = departmentName;
          }
        }

        // 활성 담당 의사 1명 확인 후 종료
        break;
      }
    }

    // ==========================================================
    // STEP 9. Integrated Data
    // ==========================================================

    final labMeasurements = data['lab_measurements'];
    final ctStudies = data['ct_studies'];
    final angiographySequences = data['angiography_sequences'];

    // ==========================================================
    // STEP 10. 실제 검사 측정값 파싱
    // ==========================================================

    final parsedLabMeasurements = labMeasurements is List
        ? labMeasurements
              .whereType<Map>()
              .map(
                (item) => PatientLabMeasurement.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <PatientLabMeasurement>[];

    // ==========================================================
    // STEP 11. Integrated Data 개수
    // ==========================================================

    final labMeasurementCount = labMeasurements is List
        ? labMeasurements.length
        : 0;

    final ctStudyCount = ctStudies is List ? ctStudies.length : 0;

    final angiographySequenceCount = angiographySequences is List
        ? angiographySequences.length
        : 0;

    return patient.copyWithIntegratedData(
      department: department,
      doctorName: doctorName,
      labMeasurements: parsedLabMeasurements,
      labMeasurementCount: labMeasurementCount,
      ctStudyCount: ctStudyCount,
      angiographySequenceCount: angiographySequenceCount,
    );
  }
}
