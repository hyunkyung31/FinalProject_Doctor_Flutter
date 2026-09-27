import 'dart:typed_data';

// ============================================================
// STEP 1. Examination 기반 MedicalResult 확보 응답
// ============================================================

class XcaMedicalResultTarget {
  final int medicalResultId;
  final String reportType;
  final String status;
  final int analysisResultId;
  final bool reused;

  const XcaMedicalResultTarget({
    required this.medicalResultId,
    required this.reportType,
    required this.status,
    required this.analysisResultId,
    required this.reused,
  });

  factory XcaMedicalResultTarget.fromJson(Map<String, dynamic> json) {
    final medical = _asMap(json['medical_result']);

    final medicalResultId = _toInt(medical['id']);

    if (medicalResultId == null || medicalResultId < 1) {
      throw const FormatException('MedicalResult ID가 없는 응답입니다.');
    }

    final analysisResultId = _toInt(json['analysis_result_id']);

    if (analysisResultId == null || analysisResultId < 1) {
      throw const FormatException('AI AnalysisResult ID가 없는 응답입니다.');
    }

    return XcaMedicalResultTarget(
      medicalResultId: medicalResultId,
      reportType: medical['report_type']?.toString() ?? 'XCA_2D',
      status: medical['status']?.toString() ?? 'DRAFT',
      analysisResultId: analysisResultId,
      reused: json['reused'] == true,
    );
  }
}

// ============================================================
// STEP 2. ReportVersion
// ============================================================

class XcaReportVersionRecord {
  final int id;
  final int versionNo;
  final String sourceType;
  final DateTime? createdAt;

  const XcaReportVersionRecord({
    required this.id,
    required this.versionNo,
    required this.sourceType,
    required this.createdAt,
  });

  factory XcaReportVersionRecord.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    final versionNo = _toInt(json['version_no']);

    if (id == null || id < 1) {
      throw const FormatException('ReportVersion ID가 없는 응답입니다.');
    }

    if (versionNo == null || versionNo < 1) {
      throw const FormatException('ReportVersion 번호가 없는 응답입니다.');
    }

    return XcaReportVersionRecord(
      id: id,
      versionNo: versionNo,
      sourceType: json['source_type']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

// ============================================================
// STEP 3. XCA Attachment 저장 결과
// ============================================================

class XcaReportDraftSaveResult {
  final int medicalResultId;
  final XcaReportVersionRecord reportVersion;
  final int? attachmentId;
  final bool reused;

  const XcaReportDraftSaveResult({
    required this.medicalResultId,
    required this.reportVersion,
    required this.attachmentId,
    required this.reused,
  });
}

// ============================================================
// STEP 4. XCA PDF Document
//
// Draft / Signed PDF bytes와 Backend가 전달한
// ReportVersion content digest를 함께 보관한다.
// ============================================================

class XcaPdfDocument {
  final Uint8List bytes;
  final String? contentSha256;
  final String? fileName;
  final bool isSigned;

  const XcaPdfDocument({
    required this.bytes,
    required this.contentSha256,
    required this.fileName,
    required this.isSigned,
  });
}

// ============================================================
// STEP 5. 재인증 결과
// ============================================================

class XcaReauthResult {
  final String token;
  final int expiresInSeconds;

  const XcaReauthResult({required this.token, required this.expiresInSeconds});
}

// ============================================================
// STEP 6. XCA 최종 확정 / 공개 결과
//
// Backend receipt의 세부 필드는 화면 동작에 필수가 아니므로
// 원본 JSON을 보존한다.
// ============================================================

class XcaReportActionResult {
  final Map<String, dynamic> data;

  const XcaReportActionResult({required this.data});
}

// ============================================================
// STEP 7. Parsing Helpers
// ============================================================

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}
