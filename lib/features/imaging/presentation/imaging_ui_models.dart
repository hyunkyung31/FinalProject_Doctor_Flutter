// ============================================================
// STEP 1. Imaging Study
// GET /api/imaging-studies/ 구조 기준
// ============================================================

class ImagingStudyUiModel {
  final int id;
  final int examinationId;

  final String studyInstanceUid;
  final String orthancStudyId;

  final String modality;

  final DateTime? studyDate;
  final String status;

  final DateTime createdAt;

  final String? errorCode;
  final String? errorMessage;

  final DateTime? validatedAt;

  final int seriesCount;
  final int instanceCount;

  // 실제 Backend 데이터가 아닌 UI 검증용 데이터 여부
  final bool isDemo;

  const ImagingStudyUiModel({
    required this.id,
    required this.examinationId,
    required this.studyInstanceUid,
    required this.orthancStudyId,
    required this.modality,
    required this.studyDate,
    required this.status,
    required this.createdAt,
    required this.errorCode,
    required this.errorMessage,
    required this.validatedAt,
    required this.seriesCount,
    required this.instanceCount,
    this.isDemo = false,
  });

  DateTime get displayDate {
    return studyDate ?? createdAt;
  }
}

// ============================================================
// STEP 2. Imaging Series
// GET /api/imaging-studies/{study_id}/series/ 구조 기준
// ============================================================

class ImagingSeriesUiModel {
  final int id;
  final int imagingStudyId;

  final String seriesInstanceUid;
  final String orthancSeriesId;

  final int? seriesNumber;

  final String modality;
  final String? bodySite;
  final String? description;

  final int instanceCount;

  const ImagingSeriesUiModel({
    required this.id,
    required this.imagingStudyId,
    required this.seriesInstanceUid,
    required this.orthancSeriesId,
    required this.seriesNumber,
    required this.modality,
    required this.bodySite,
    required this.description,
    required this.instanceCount,
  });
}

// ============================================================
// STEP 3. Imaging Instance
// GET /api/imaging-series/{series_id}/instances/ 구조 기준
// ============================================================

class ImagingInstanceUiModel {
  final int id;
  final int imagingSeriesId;

  final String sopInstanceUid;
  final String orthancInstanceId;
  final String sopClassUid;

  final int? instanceNumber;

  final String storageBackend;
  final String mimeType;

  final DateTime createdAt;

  const ImagingInstanceUiModel({
    required this.id,
    required this.imagingSeriesId,
    required this.sopInstanceUid,
    required this.orthancInstanceId,
    required this.sopClassUid,
    required this.instanceNumber,
    required this.storageBackend,
    required this.mimeType,
    required this.createdAt,
  });
}

// ============================================================
// STEP 4. Viewer Mode
// ============================================================

enum ImagingViewerMode { slice2d, vessel3d }

// ============================================================
// STEP 5. Helpers
// ============================================================

extension ImagingStudyUiExtension on ImagingStudyUiModel {
  String get statusLabel {
    switch (status) {
      case 'RECEIVED':
        return '수신 완료';

      case 'VALIDATED':
        return '검증 완료';

      case 'ERROR':
        return '오류';

      default:
        return status;
    }
  }
}
