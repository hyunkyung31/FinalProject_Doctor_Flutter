import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/xca_report_models.dart';

// ============================================================
// STEP 1. XCA Report Service
// ============================================================

class XcaReportService {
  final ApiClient apiClient;

  const XcaReportService({required this.apiClient});

  // ==========================================================
  // STEP 2. Examination 기반 MedicalResult 확보
  //
  // POST /api/examinations/{examination_id}/medical-results/
  // ==========================================================

  Future<XcaMedicalResultTarget> prepareMedicalResult({
    required int examinationId,
    required int patientId,
    required int analysisResultId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/examinations/$examinationId/medical-results/',
        data: {
          'patient_id': patientId,
          'report_type': 'XCA_2D',
          'analysis_result_id': analysisResultId,
        },
      );

      if (response.data is! Map) {
        throw const XcaReportException('MedicalResult 응답 형식이 올바르지 않습니다.');
      }

      return XcaMedicalResultTarget.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw _toReportException(
        error,
        fallback: 'XCA 보고서 대상 MedicalResult를 준비하지 못했습니다.',
      );
    }
  }

  // ==========================================================
  // STEP 3. ReportVersion 목록
  //
  // GET /api/medical-results/{result_id}/versions/
  // ==========================================================

  Future<List<XcaReportVersionRecord>> fetchVersions(
    int medicalResultId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/medical-results/$medicalResultId/versions/',
      );

      if (response.data is! List) {
        throw const XcaReportException('ReportVersion 목록 응답 형식이 올바르지 않습니다.');
      }

      final versions = (response.data as List)
          .whereType<Map>()
          .map(
            (item) => XcaReportVersionRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      versions.sort((a, b) => b.versionNo.compareTo(a.versionNo));

      return versions;
    } on DioException catch (error) {
      throw _toReportException(error, fallback: '최신 보고서 버전을 조회하지 못했습니다.');
    }
  }

  // ==========================================================
  // STEP 4. XCA Frame을 보고서 초안에 첨부
  //
  // POST /api/medical-results/{result_id}/xca-attachments/
  // ==========================================================

  Future<XcaReportDraftSaveResult> attachFrames({
    required int medicalResultId,
    required int detailId,
    required List<int> frameIds,
    required String reviewNote,
    required int? baseVersionId,
  }) async {
    final note = reviewNote.trim();

    if (frameIds.isEmpty) {
      throw const XcaReportException('보고서에 첨부할 Frame을 선택해주세요.');
    }

    if (frameIds.length > 12) {
      throw const XcaReportException('보고서 Frame은 최대 12개까지 선택할 수 있습니다.');
    }

    if (frameIds.toSet().length != frameIds.length) {
      throw const XcaReportException('중복된 Frame이 선택되어 있습니다.');
    }

    if (note.isEmpty) {
      throw const XcaReportException('의료진 의견을 입력해주세요.');
    }

    if (note.length > 4000) {
      throw const XcaReportException('의료진 의견은 4000자 이하로 입력해주세요.');
    }

    try {
      final response = await apiClient.dio.post(
        '/medical-results/$medicalResultId/xca-attachments/',
        data: {
          'detail_id': detailId,
          'frame_ids': frameIds,
          'review_note': note,
          'base_version_id': baseVersionId,
        },
      );

      if (response.data is! Map) {
        throw const XcaReportException('XCA 보고서 저장 응답 형식이 올바르지 않습니다.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      final reportVersionRaw = data['report_version'];

      if (reportVersionRaw is! Map) {
        throw const XcaReportException('저장된 ReportVersion 정보가 없습니다.');
      }

      return XcaReportDraftSaveResult(
        medicalResultId: medicalResultId,
        reportVersion: XcaReportVersionRecord.fromJson(
          Map<String, dynamic>.from(reportVersionRaw),
        ),
        attachmentId: _readInt(data['attachment_id']),
        reused: data['reused'] == true,
      );
    } on DioException catch (error) {
      throw _toReportException(
        error,
        fallback: 'XCA Frame을 보고서 초안에 저장하지 못했습니다.',
      );
    }
  }

  // ==========================================================
  // STEP 5. XCA Draft / Signed PDF 조회
  //
  // GET /api/report-versions/{version_id}/xca-pdf/
  //     ?patient_id={patient_id}
  //
  // 주의:
  // DRF Content Negotiation 때문에 Accept: application/pdf는
  // 보내지 않는다. responseType만 bytes로 지정한다.
  // ==========================================================

  Future<XcaPdfDocument> fetchXcaPdfDocument({
    required int versionId,
    required int patientId,
  }) async {
    try {
      final response = await apiClient.dio.get<List<int>>(
        '/report-versions/$versionId/xca-pdf/',
        queryParameters: {'patient_id': patientId},
        options: Options(responseType: ResponseType.bytes),
      );

      final raw = response.data;

      if (raw == null || raw.isEmpty) {
        throw const XcaReportException('PDF 응답이 비어 있습니다.');
      }

      final bytes = Uint8List.fromList(raw);

      final isPdf =
          bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;

      if (!isPdf) {
        throw const XcaReportException('서버 응답이 PDF 형식이 아닙니다.');
      }

      final fileName = _readFileName(response.headers);

      final contentSha256 = _readContentSha256(response.headers);

      final lowerFileName = fileName?.toLowerCase();

      final isSigned =
          lowerFileName != null &&
          lowerFileName.isNotEmpty &&
          !lowerFileName.contains('draft');

      return XcaPdfDocument(
        bytes: bytes,
        contentSha256: contentSha256,
        fileName: fileName,
        isSigned: isSigned,
      );
    } on DioException catch (error) {
      throw _toReportException(error, fallback: 'XCA 보고서 PDF를 불러오지 못했습니다.');
    }
  }

  // 기존 호출부가 남아 있어도 깨지지 않도록 유지한다.
  Future<Uint8List> fetchXcaPdfBytes({
    required int versionId,
    required int patientId,
  }) async {
    final document = await fetchXcaPdfDocument(
      versionId: versionId,
      patientId: patientId,
    );

    return document.bytes;
  }

  // ==========================================================
  // STEP 6. 의료진 재인증
  //
  // POST /api/staff/reauthenticate/
  // ==========================================================

  Future<XcaReauthResult> reauthenticatePassword({
    required String password,
  }) async {
    final credential = password.trim();

    if (credential.isEmpty) {
      throw const XcaReportException('비밀번호를 입력해주세요.');
    }

    try {
      final response = await apiClient.dio.post(
        '/staff/reauthenticate/',
        data: {'auth_method': 'PASSWORD', 'credential': credential},
      );

      if (response.data is! Map) {
        throw const XcaReportException('재인증 응답 형식이 올바르지 않습니다.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      final token = data['reauth_token']?.toString().trim() ?? '';

      final expiresIn = _readInt(data['expires_in']) ?? 0;

      if (token.isEmpty || expiresIn <= 0) {
        throw const XcaReportException('재인증 토큰을 확인할 수 없습니다.');
      }

      return XcaReauthResult(token: token, expiresInSeconds: expiresIn);
    } on DioException catch (error) {
      throw _toReportException(error, fallback: '의료진 재인증에 실패했습니다.');
    }
  }

  // ==========================================================
  // STEP 7. XCA 최종 확정 / 서명
  //
  // POST /api/report-versions/{version_id}/xca-finalize/
  //
  // content_sha256은 의료진이 확인한 Draft PDF와
  // 동일한 ReportVersion인지 서버가 재검증하기 위한 값이다.
  // ==========================================================

  Future<XcaReportActionResult> finalizeXcaReport({
    required int versionId,
    required int patientId,
    required int medicalResultId,
    required String contentSha256,
    required String reauthToken,
  }) async {
    final digest = contentSha256.trim().toLowerCase();

    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      throw const XcaReportException(
        '보고서 무결성 해시를 확인할 수 없습니다. '
        'Draft PDF를 다시 열어주세요.',
      );
    }

    try {
      final response = await apiClient.dio.post(
        '/report-versions/$versionId/xca-finalize/',
        data: {
          'patient_id': patientId,
          'medical_result_id': medicalResultId,
          'content_sha256': digest,
          'reauth_token': reauthToken,
          'confirm_reviewed': true,
        },
      );

      return XcaReportActionResult(data: _asResponseMap(response.data));
    } on DioException catch (error) {
      throw _toReportException(error, fallback: 'XCA 보고서 최종 확정을 완료하지 못했습니다.');
    }
  }

  // ==========================================================
  // STEP 8. 환자 공개
  //
  // POST /api/report-versions/{version_id}/xca-release/
  // ==========================================================

  Future<XcaReportActionResult> releaseXcaReport({
    required int versionId,
    required int patientId,
    required int medicalResultId,
    required String reauthToken,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/report-versions/$versionId/xca-release/',
        data: {
          'patient_id': patientId,
          'medical_result_id': medicalResultId,
          'reauth_token': reauthToken,
          'confirm_release': true,
        },
      );

      return XcaReportActionResult(data: _asResponseMap(response.data));
    } on DioException catch (error) {
      throw _toReportException(error, fallback: 'XCA 보고서를 환자에게 공개하지 못했습니다.');
    }
  }

  // ==========================================================
  // STEP 9. Viewer에서 사용하는 전체 Draft 저장 Flow
  // ==========================================================

  Future<XcaReportDraftSaveResult> saveXcaDraft({
    required int examinationId,
    required int patientId,
    required int analysisResultId,
    required int detailId,
    required List<int> frameIds,
    required String reviewNote,
  }) async {
    final target = await prepareMedicalResult(
      examinationId: examinationId,
      patientId: patientId,
      analysisResultId: analysisResultId,
    );

    final versions = await fetchVersions(target.medicalResultId);

    final baseVersionId = versions.isEmpty ? null : versions.first.id;

    return attachFrames(
      medicalResultId: target.medicalResultId,
      detailId: detailId,
      frameIds: frameIds,
      reviewNote: reviewNote,
      baseVersionId: baseVersionId,
    );
  }
}

// ============================================================
// STEP 10. Report Exceptions
// ============================================================

class XcaReportException implements Exception {
  final String message;

  const XcaReportException(this.message);

  @override
  String toString() => message;
}

class XcaReportConflictException extends XcaReportException {
  const XcaReportConflictException(super.message);
}

class XcaReportUnauthorizedException extends XcaReportException {
  const XcaReportUnauthorizedException(super.message);
}

class XcaReportUncertainException extends XcaReportException {
  const XcaReportUncertainException(super.message);
}

// ============================================================
// STEP 11. Error / Header Helpers
// ============================================================

XcaReportException _toReportException(
  DioException error, {
  required String fallback,
}) {
  final detail = _extractDetail(error.response?.data);

  final message = detail ?? fallback;

  switch (error.response?.statusCode) {
    case 401:
      return XcaReportUnauthorizedException(message);

    case 409:
      return XcaReportConflictException(message);

    case 503:
      return XcaReportUncertainException(message);

    default:
      return XcaReportException(message);
  }
}

String? _extractDetail(dynamic data) {
  if (data is List<int>) {
    try {
      final decoded = utf8.decode(data, allowMalformed: true);

      final parsed = jsonDecode(decoded);

      return _extractDetail(parsed);
    } catch (_) {
      return null;
    }
  }

  if (data is Uint8List) {
    return _extractDetail(data.toList(growable: false));
  }

  if (data is Map) {
    final detail = data['detail'];

    if (detail != null) {
      final value = detail.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    for (final entry in data.entries) {
      final value = entry.value;

      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }

      if (value != null) {
        final message = value.toString().trim();

        if (message.isNotEmpty) {
          return message;
        }
      }
    }
  }

  return null;
}

String? _readContentSha256(Headers headers) {
  final candidates = <String>[];

  for (final entry in headers.map.entries) {
    final key = entry.key.toLowerCase();

    if (key.contains('sha256') ||
        key.contains('sha-256') ||
        key.contains('digest')) {
      candidates.addAll(entry.value);
    }
  }

  final hex64 = RegExp(r'(?<![a-fA-F0-9])([a-fA-F0-9]{64})(?![a-fA-F0-9])');

  for (final value in candidates) {
    final match = hex64.firstMatch(value);

    if (match != null) {
      return match.group(1)?.toLowerCase();
    }
  }

  return null;
}

String? _readFileName(Headers headers) {
  final disposition = headers.value('content-disposition');

  if (disposition == null || disposition.trim().isEmpty) {
    return null;
  }

  final match = RegExp(
    r'filename="?([^";]+)"?',
    caseSensitive: false,
  ).firstMatch(disposition);

  return match?.group(1)?.trim();
}

Map<String, dynamic> _asResponseMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}
