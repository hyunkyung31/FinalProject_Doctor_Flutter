import 'package:flutter/foundation.dart';

import '../../presentation/imaging_ui_models.dart';

// ============================================================
// STEP 1. Imaging API Service
// 실제 Backend 의료영상 API 응답을 UI Model로 변환한다.
// ============================================================

class ImagingService {
  final dynamic apiClient;

  const ImagingService({required this.apiClient});

  // ============================================================
  // STEP 2. Study 목록
  // GET /imaging-studies/
  // ============================================================

  Future<List<ImagingStudyUiModel>> fetchStudies({
    int? patientId,
    int? examinationId,
  }) async {
    final response = await apiClient.dio.get(
      '/imaging-studies/',
      queryParameters: {
        'patient_id': ?patientId,
        'examination_id': ?examinationId,
      },
    );

    final studies = _extractList(response.data).map(_studyFromJson).toList();

    studies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 영상 메뉴 직접 진입 시 너무 많은 Study가 한 번에
    // 렌더링되지 않도록 최근 100건만 사용한다.
    if (studies.length > 100) {
      return studies.take(100).toList();
    }

    return studies;
  }

  // ============================================================
  // STEP 3. Series 목록
  // GET /imaging-studies/{studyId}/series/
  // ============================================================

  Future<List<ImagingSeriesUiModel>> fetchSeries(int studyId) async {
    final response = await apiClient.dio.get(
      '/imaging-studies/$studyId/series/',
    );

    final series = _extractList(response.data).map(_seriesFromJson).toList();

    series.sort((a, b) {
      final aNumber = a.seriesNumber ?? 1 << 30;
      final bNumber = b.seriesNumber ?? 1 << 30;

      final numberCompare = aNumber.compareTo(bNumber);

      if (numberCompare != 0) {
        return numberCompare;
      }

      return a.id.compareTo(b.id);
    });

    return series;
  }

  // ============================================================
  // STEP 4. Study 3D Rendering 목록
  // GET /staff/imaging-studies/{studyId}/renderings-3d/
  // ============================================================
  Future<List<Map<String, dynamic>>> fetchRenderings(int studyId) async {
    final response = await apiClient.dio.get(
      '/staff/imaging-studies/$studyId/renderings-3d/',
    );

    final renderings = _extractList(response.data);

    debugPrint(
      '[IMAGING 3D] Study #$studyId Rendering ${renderings.length}건: $renderings',
      wrapWidth: 2048,
    );

    return renderings;
  }

  // ============================================================
  // STEP 5. Study Parser
  // ============================================================

  ImagingStudyUiModel _studyFromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);

    if (id == null) {
      throw const FormatException('영상 Study ID가 없습니다.');
    }

    final examinationId = _toInt(json['examination'] ?? json['examination_id']);

    if (examinationId == null) {
      throw FormatException('Study #$id의 검사 ID가 없습니다.');
    }

    return ImagingStudyUiModel(
      id: id,
      examinationId: examinationId,
      studyInstanceUid:
          _string(json['study_instance_uid'] ?? json['studyInstanceUid']) ?? '',
      orthancStudyId:
          _string(json['orthanc_study_id'] ?? json['orthancStudyId']) ?? '',
      modality: _string(json['modality']) ?? '-',
      studyDate: _toDateTime(json['study_date'] ?? json['studyDate']),
      status: _string(json['status']) ?? '-',
      createdAt:
          _toDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      errorCode: _string(json['error_code'] ?? json['errorCode']),
      errorMessage: _string(json['error_message'] ?? json['errorMessage']),
      validatedAt: _toDateTime(json['validated_at'] ?? json['validatedAt']),
      seriesCount: _toInt(json['series_count'] ?? json['seriesCount']) ?? 0,
      instanceCount:
          _toInt(json['instance_count'] ?? json['instanceCount']) ?? 0,
      isDemo: false,
    );
  }

  // ============================================================
  // STEP 6. Series Parser
  // ============================================================

  ImagingSeriesUiModel _seriesFromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);

    if (id == null) {
      throw const FormatException('영상 Series ID가 없습니다.');
    }

    final imagingStudyId = _toInt(
      json['imaging_study'] ?? json['imaging_study_id'] ?? json['study_id'],
    );

    if (imagingStudyId == null) {
      throw FormatException('Series #$id의 Study ID가 없습니다.');
    }

    return ImagingSeriesUiModel(
      id: id,
      imagingStudyId: imagingStudyId,
      seriesInstanceUid:
          _string(json['series_instance_uid'] ?? json['seriesInstanceUid']) ??
          '',
      orthancSeriesId:
          _string(json['orthanc_series_id'] ?? json['orthancSeriesId']) ?? '',
      seriesNumber: _toInt(json['series_number'] ?? json['seriesNumber']),
      modality: _string(json['modality']) ?? '-',
      bodySite: _string(json['body_site'] ?? json['bodySite']),
      description:
          _string(json['description'] ?? json['series_description']) ??
          'Series #$id',
      instanceCount:
          _toInt(
            json['instance_count'] ?? json['instanceCount'] ?? json['count'],
          ) ??
          0,
    );
  }

  // ============================================================
  // STEP 7. Response Parsing
  // List / DRF Pagination 모두 대응
  // ============================================================

  List<Map<String, dynamic>> _extractList(dynamic data) {
    dynamic raw = data;

    if (data is Map && data['results'] is List) {
      raw = data['results'];
    }

    if (raw is! List) {
      throw const FormatException('의료영상 목록 응답 형식이 올바르지 않습니다.');
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _toInt(dynamic value) {
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

  DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  String? _string(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}
