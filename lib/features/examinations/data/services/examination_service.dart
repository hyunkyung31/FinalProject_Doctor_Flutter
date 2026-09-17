import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../presentation/examination_ui_models.dart';

// ============================================================
// STEP 1. Examination Service
// 실제 Examination API 연결
// ============================================================

class ExaminationService {
  final ApiClient apiClient;

  ExaminationService({required this.apiClient});

  // ==========================================================
  // STEP 2. 검사 종류 조회
  // GET /examinations/types/
  // ==========================================================

  Future<List<ExaminationTypeUiModel>> fetchExaminationTypes() async {
    final response = await apiClient.dio.get(ApiEndpoints.examinationTypes);

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('검사 종류 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('검사 종류 항목 형식이 올바르지 않습니다.');
      }

      return ExaminationTypeUiModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ==========================================================
  // STEP 3. 검사 오더 조회
  // GET /examinations/orders/
  // ==========================================================

  Future<List<ExaminationOrderUiModel>> fetchExaminationOrders() async {
    final response = await apiClient.dio.get(ApiEndpoints.examinationOrders);

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('검사 오더 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('검사 오더 항목 형식이 올바르지 않습니다.');
      }

      return ExaminationOrderUiModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ==========================================================
  // STEP 4. Encounter 조회
  // GET /encounters/
  // ==========================================================

  Future<List<ExaminationEncounterUiModel>> fetchEncounters() async {
    final response = await apiClient.dio.get(ApiEndpoints.encounters);

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('Encounter 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('Encounter 항목 형식이 올바르지 않습니다.');
      }

      return ExaminationEncounterUiModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }
  // ============================================================
  // STEP. 검사 오더 생성
  // POST /api/examinations/orders/
  // ============================================================

  Future<ExaminationOrderUiModel> createExaminationOrder({
    required int encounterId,
    required int examinationTypeId,
    String priority = 'NORMAL',
    String? clinicalNote,
  }) async {
    final normalizedNote = clinicalNote?.trim();

    final response = await apiClient.dio.post(
      ApiEndpoints.examinationOrders,
      data: {
        'encounter_id': encounterId,

        // Swagger 스키마에 두 필드가 모두 존재하므로
        // 현재 Backend 스펙에 맞춰 동일한 검사 종류 ID 전달
        'type_id': examinationTypeId,
        'examination_type_id': examinationTypeId,

        'priority': priority,
        'clinical_note': normalizedNote == null || normalizedNote.isEmpty
            ? null
            : normalizedNote,
      },
    );

    if (response.data is! Map) {
      throw const FormatException('검사 오더 생성 응답 형식이 올바르지 않습니다.');
    }

    return ExaminationOrderUiModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // 검사 오더 수정
  // PATCH /api/examinations/orders/{orderId}/
  Future<ExaminationOrderUiModel> updateExaminationOrder({
    required int orderId,
    required String priority,
    required String clinicalNote,
  }) async {
    final normalizedNote = clinicalNote.trim();

    final response = await apiClient.dio.patch(
      '/examinations/orders/$orderId/',
      data: {
        'priority': priority,
        'clinical_note': normalizedNote.isEmpty ? null : normalizedNote,
      },
    );

    if (response.data is! Map) {
      throw const FormatException('검사 오더 수정 응답 형식이 올바르지 않습니다.');
    }

    return ExaminationOrderUiModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ============================================================
  // STEP. 검사 수행 생성
  // POST /api/examinations/orders/{orderId}/examinations/
  // ============================================================

  Future<ExaminationExecutionUiModel> createExaminationExecution({
    required int orderId,
    required String location,
    int attemptNo = 1,
  }) async {
    final normalizedLocation = location.trim();

    if (normalizedLocation.isEmpty) {
      throw const FormatException('검사 장소를 입력해야 합니다.');
    }

    final response = await apiClient.dio.post(
      '/examinations/orders/$orderId/examinations/',
      data: {'attempt_no': attemptNo, 'location': normalizedLocation},
    );

    if (response.data is! Map) {
      throw const FormatException('검사 수행 생성 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final examinationId = data['id'];

    if (examinationId is! num) {
      throw const FormatException('생성된 검사 수행 ID를 확인할 수 없습니다.');
    }

    return fetchExaminationExecution(examinationId.toInt());
  }

  // ============================================================
  // 검사 오더별 수행 이력 조회
  // GET /api/examinations/orders/{orderId}/examinations/
  // ============================================================

  Future<List<ExaminationExecutionUiModel>> fetchExaminationExecutionsByOrder(
    int orderId,
  ) async {
    final response = await apiClient.dio.get(
      '/examinations/orders/$orderId/examinations/',
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('검사 수행 이력 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('검사 수행 이력 항목 형식이 올바르지 않습니다.');
      }

      return ExaminationExecutionUiModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // ============================================================
  // 검사 수행 상세 조회
  // GET /api/examinations/{examinationId}/
  // ============================================================

  Future<ExaminationExecutionUiModel> fetchExaminationExecution(
    int examinationId,
  ) async {
    final response = await apiClient.dio.get('/examinations/$examinationId/');

    if (response.data is! Map) {
      throw const FormatException('검사 수행 상세 응답 형식이 올바르지 않습니다.');
    }

    return ExaminationExecutionUiModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ============================================================
  // STEP. 검사 수행 시작
  // POST /api/examinations/{examinationId}/start/
  // ============================================================

  Future<ExaminationExecutionUiModel> startExaminationExecution(
    int examinationId,
  ) async {
    await apiClient.dio.post('/examinations/$examinationId/start/');

    return fetchExaminationExecution(examinationId);
  }

  // ============================================================
  // STEP. 검사 수행 완료
  // POST /api/examinations/{examinationId}/complete/
  // ============================================================

  Future<ExaminationExecutionUiModel> completeExaminationExecution(
    int examinationId,
  ) async {
    await apiClient.dio.post(
      '/examinations/$examinationId/complete/',
      data: {'performed_at': DateTime.now().toUtc().toIso8601String()},
    );

    return fetchExaminationExecution(examinationId);
  }

  // ============================================================
  // STEP. 검사 수행 실패
  // POST /api/examinations/{examinationId}/fail/
  // ============================================================

  Future<ExaminationExecutionUiModel> failExaminationExecution({
    required int examinationId,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();

    if (normalizedReason.isEmpty) {
      throw const FormatException('검사 실패 사유를 입력해야 합니다.');
    }

    await apiClient.dio.post(
      '/examinations/$examinationId/fail/',
      data: {'reason': normalizedReason},
    );

    return fetchExaminationExecution(examinationId);
  }

  // ============================================================
  // 검사 수행별 결과 목록 조회
  // GET /api/examinations/{examinationId}/results/
  // ============================================================

  Future<List<ExaminationResultUiModel>> fetchExaminationResults(
    int examinationId,
  ) async {
    final response = await apiClient.dio.get(
      '/examinations/$examinationId/results/',
    );

    final responseData = response.data;

    if (responseData is! List) {
      throw const FormatException('검사 결과 목록 응답 형식이 올바르지 않습니다.');
    }

    return responseData.map((item) {
      if (item is! Map) {
        throw const FormatException('검사 결과 목록 항목 형식이 올바르지 않습니다.');
      }

      return ExaminationResultUiModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ============================================================
  // 검사 결과 상세 조회
  // GET /api/examinations/results/{resultId}/
  // ============================================================

  Future<ExaminationResultUiModel> fetchExaminationResultDetail(
    int resultId,
  ) async {
    final response = await apiClient.dio.get(
      '/examinations/results/$resultId/',
    );

    if (response.data is! Map) {
      throw const FormatException('검사 결과 상세 응답 형식이 올바르지 않습니다.');
    }

    return ExaminationResultUiModel.fromDetailJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
