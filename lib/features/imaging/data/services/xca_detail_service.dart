import '../../../../core/network/api_client.dart';
import '../models/xca_detail_models.dart';

// ============================================================
// STEP 1. XCA Detail Service
// ============================================================

class XcaDetailService {
  final ApiClient apiClient;

  const XcaDetailService({required this.apiClient});

  // ==========================================================
  // STEP 2. Examination XCA Detail 조회
  //
  // GET
  // /examinations/{examinationId}/xca-details/
  // ?patient_id={patientId}
  // ==========================================================

  Future<List<XcaDetailRecord>> fetchDetails({
    required int examinationId,
    required int patientId,
  }) async {
    final response = await apiClient.dio.get(
      '/examinations/$examinationId/xca-details/',
      queryParameters: {'patient_id': patientId},
    );

    if (response.data is! Map) {
      throw const FormatException('XCA Detail 목록 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final resultsData = data['results'];

    if (resultsData is! List) {
      return [];
    }

    return resultsData
        .whereType<Map>()
        .map(
          (item) => XcaDetailRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ==========================================================
  // STEP 3. 특정 Analysis에 해당하는 Detail 선택
  // ==========================================================

  Future<XcaDetailRecord> fetchDetailForAnalysis({
    required int examinationId,
    required int patientId,
    int? analysisId,
  }) async {
    final details = await fetchDetails(
      examinationId: examinationId,
      patientId: patientId,
    );

    if (details.isEmpty) {
      throw StateError('해당 검사에 연결된 XCA Detail이 없습니다.');
    }

    if (analysisId != null) {
      for (final detail in details) {
        if (detail.analysisId == analysisId) {
          return detail;
        }
      }
    }

    details.sort((a, b) => b.id.compareTo(a.id));

    return details.first;
  }

  // ==========================================================
  // STEP 4. 특정 Sequence의 전체 Frame 조회
  //
  // Backend는 page_size=50 pagination 사용
  // next_page가 null이 될 때까지 반복
  // ==========================================================

  Future<List<XcaFrameRecord>> fetchSequenceFrames({
    required int detailId,
    required int patientId,
    required int sequenceId,
  }) async {
    final frames = <XcaFrameRecord>[];

    int page = 1;
    int safetyCount = 0;

    while (true) {
      safetyCount += 1;

      if (safetyCount > 50) {
        throw StateError('XCA Frame pagination 횟수가 비정상적으로 많습니다.');
      }

      final response = await apiClient.dio.get(
        '/xca-details/$detailId/frames/',
        queryParameters: {
          'patient_id': patientId,
          'sequence_id': sequenceId,
          'page': page,
          'page_size': 50,
        },
      );

      if (response.data is! Map) {
        throw const FormatException('XCA Frame 응답 형식이 올바르지 않습니다.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      final frameData = data['frames'];

      if (frameData is List) {
        for (final item in frameData.whereType<Map>()) {
          frames.add(XcaFrameRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      final nextPage = _toNullableInt(data['next_page']);

      if (nextPage == null) {
        break;
      }

      page = nextPage;
    }

    frames.sort((a, b) => a.frameIndex.compareTo(b.frameIndex));

    return frames;
  }
}

// ============================================================
// STEP 5. Parser
// ============================================================

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
