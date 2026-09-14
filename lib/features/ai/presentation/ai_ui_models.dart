// ============================================================
// STEP 1. AI Analysis
// GET /api/ai-analyses/ 구조 기반
// ============================================================

class AiAnalysisUiModel {
  final int id;
  final int examinationId;
  final int requestedBy;

  final String analysisType;
  final String status;

  final DateTime requestedAt;
  final DateTime? completedAt;

  final bool isDemo;

  // 화면 확인용 표시 정보
  // 실제 연결 시 Examination → Encounter → Patient로 교체
  final String patientName;
  final String patientMeta;

  const AiAnalysisUiModel({
    required this.id,
    required this.examinationId,
    required this.requestedBy,
    required this.analysisType,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
    required this.patientName,
    required this.patientMeta,
    this.isDemo = false,
  });

  AiAnalysisUiModel copyWith({String? status, DateTime? completedAt}) {
    return AiAnalysisUiModel(
      id: id,
      examinationId: examinationId,
      requestedBy: requestedBy,
      analysisType: analysisType,
      status: status ?? this.status,
      requestedAt: requestedAt,
      completedAt: completedAt ?? this.completedAt,
      patientName: patientName,
      patientMeta: patientMeta,
      isDemo: isDemo,
    );
  }
}

// ============================================================
// STEP 2. AI Input
// GET /api/ai-analyses/{id}/inputs/
// ============================================================

class AiInputUiModel {
  final int id;
  final int analysisId;

  final String inputType;

  final int? examinationResultId;
  final int? imagingStudyId;
  final int? imagingSeriesId;
  final int? fileAssetId;

  final String validationStatus;
  final String? validationMessage;

  final String sourceLabel;

  const AiInputUiModel({
    required this.id,
    required this.analysisId,
    required this.inputType,
    required this.examinationResultId,
    required this.imagingStudyId,
    required this.imagingSeriesId,
    required this.fileAssetId,
    required this.validationStatus,
    required this.validationMessage,
    required this.sourceLabel,
  });
}

// ============================================================
// STEP 3. Detection
// UI DEMO
// 실제 연결 시 /detections/ 응답으로 교체
// ============================================================

class AiDetectionUiModel {
  final String vessel;
  final String location;
  final double confidence;
  final String severity;

  const AiDetectionUiModel({
    required this.vessel,
    required this.location,
    required this.confidence,
    required this.severity,
  });
}

// ============================================================
// STEP 4. Lesion
// ============================================================

class AiLesionUiModel {
  final String vessel;
  final String segment;
  final double stenosisPercent;
  final String riskLevel;

  const AiLesionUiModel({
    required this.vessel,
    required this.segment,
    required this.stenosisPercent,
    required this.riskLevel,
  });
}

// ============================================================
// STEP 5. Segmentation
// ============================================================

class AiSegmentationUiModel {
  final String vessel;
  final String status;

  const AiSegmentationUiModel({required this.vessel, required this.status});
}

// ============================================================
// STEP 6. CAC Score
// ============================================================

class AiCacScoreUiModel {
  final double lad;
  final double lcx;
  final double rca;
  final double total;

  const AiCacScoreUiModel({
    required this.lad,
    required this.lcx,
    required this.rca,
    required this.total,
  });
}

// ============================================================
// STEP 7. AI Result
// 현재 실제 Result 미생성 → UI DEMO Model
// ============================================================

class AiResultUiModel {
  final int id;
  final int analysisId;
  final int examinationId;

  final String patientName;
  final String patientMeta;

  final String analysisType;
  final String status;

  final String summary;
  final String modelLabel;

  final List<AiDetectionUiModel> detections;
  final List<AiLesionUiModel> lesions;
  final List<AiSegmentationUiModel> segmentations;

  final AiCacScoreUiModel? cacScore;

  final String? explanation;

  final bool isDemo;

  const AiResultUiModel({
    required this.id,
    required this.analysisId,
    required this.examinationId,
    required this.patientName,
    required this.patientMeta,
    required this.analysisType,
    required this.status,
    required this.summary,
    required this.modelLabel,
    required this.detections,
    required this.lesions,
    required this.segmentations,
    required this.cacScore,
    required this.explanation,
    this.isDemo = true,
  });
}

// ============================================================
// STEP 8. CDSS Risk Component
// ============================================================

class CdssRiskComponentUiModel {
  final String title;
  final String value;
  final String level;
  final String description;

  const CdssRiskComponentUiModel({
    required this.title,
    required this.value,
    required this.level,
    required this.description,
  });
}

// ============================================================
// STEP 9. CDSS Source
// ============================================================

class CdssSourceUiModel {
  final String sourceType;
  final String title;
  final String description;

  const CdssSourceUiModel({
    required this.sourceType,
    required this.title,
    required this.description,
  });
}

// ============================================================
// STEP 10. CDSS Recommendation
// ============================================================

class CdssRecommendationUiModel {
  final String title;
  final String description;
  final String priority;

  const CdssRecommendationUiModel({
    required this.title,
    required this.description,
    required this.priority,
  });
}

// ============================================================
// STEP 11. CDSS Assessment
//
// 실제 생성 Request에서 확인된 관계:
// patient
// encounter_id
// ai_result_ids[]
// ruleset_version
//
// 상세 응답 Schema는 아직 미확인 → UI DEMO
// ============================================================

class CdssAssessmentUiModel {
  final int id;

  final int patientId;
  final int encounterId;

  final String patientName;
  final String patientMeta;

  final List<int> aiResultIds;

  final String rulesetVersion;

  final String riskLevel;
  final String summary;

  final List<CdssRiskComponentUiModel> riskComponents;
  final List<CdssSourceUiModel> sources;
  final List<CdssRecommendationUiModel> recommendations;

  final bool isDemo;

  const CdssAssessmentUiModel({
    required this.id,
    required this.patientId,
    required this.encounterId,
    required this.patientName,
    required this.patientMeta,
    required this.aiResultIds,
    required this.rulesetVersion,
    required this.riskLevel,
    required this.summary,
    required this.riskComponents,
    required this.sources,
    required this.recommendations,
    this.isDemo = true,
  });
}
