import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'ai_ui_models.dart';
import 'widgets/ai_analysis_panel.dart';
import 'widgets/ai_result_panel.dart';
import 'widgets/ai_section_tabs.dart';
import 'widgets/cdss_assessment_panel.dart';

// ============================================================
// STEP 1. AI Page
// ============================================================

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  AiSection _selectedSection = AiSection.analyses;

  late List<AiAnalysisUiModel> _analyses;

  late final List<AiInputUiModel> _inputs;

  late final List<AiResultUiModel> _results;

  late final List<CdssAssessmentUiModel> _assessments;

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _analyses = _buildAnalyses();
    _inputs = _buildInputs();
    _results = _buildResults();
    _assessments = _buildAssessments();
  }

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: 'AI',
      selectedIndex: 5,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiSectionTabs(
                selectedSection: _selectedSection,
                onChanged: (section) {
                  setState(() {
                    _selectedSection = section;
                  });
                },
              ),

              const SizedBox(height: 10),

              Expanded(child: _buildSelectedSection()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 4. Selected Section
  // ============================================================

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case AiSection.analyses:
        return AiAnalysisPanel(
          analyses: _analyses,
          inputs: _inputs,
          onCreateAnalysis: () {
            _showMessage('실제 AI 분석 요청 API 연결 전 UI Preview입니다.');
          },
          onRetry: _retryAnalysis,
          onCancel: _cancelAnalysis,
        );

      case AiSection.results:
        return AiResultPanel(
          results: _results,
          onOpenImaging: () {
            context.go(AppRoutes.imaging);
          },
        );

      case AiSection.integratedAssessment:
        return CdssAssessmentPanel(
          assessments: _assessments,
          onCreateAssessment: () {
            _showMessage('현재 실제 AI Result가 없어 CDSS Assessment 생성은 연결하지 않았습니다.');
          },
          onRecalculate: () {
            _showMessage('CDSS 재평가 API 연결 전 UI Preview입니다.');
          },
        );
    }
  }

  // ============================================================
  // STEP 5. Analysis Actions
  // ============================================================

  void _retryAnalysis(AiAnalysisUiModel analysis) {
    final index = _analyses.indexWhere((item) => item.id == analysis.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _analyses[index] = analysis.copyWith(
        status: 'RUNNING',
        completedAt: null,
      );
    });

    _showMessage('AI 분석 재시도 상태로 변경했습니다. 실제 API는 아직 연결하지 않았습니다.');
  }

  void _cancelAnalysis(AiAnalysisUiModel analysis) {
    final index = _analyses.indexWhere((item) => item.id == analysis.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _analyses[index] = analysis.copyWith(
        status: 'CANCELED',
        completedAt: DateTime.now(),
      );
    });

    _showMessage('AI 분석이 UI에서 취소 처리되었습니다.');
  }

  // ============================================================
  // STEP 6. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // STEP 7. Analyses
  //
  // #453 / #452 / #451 = 실제 목록 구조 기반
  // 그 외 상태 테스트용 DEMO
  // ============================================================

  List<AiAnalysisUiModel> _buildAnalyses() {
    return [
      AiAnalysisUiModel(
        id: 453,
        examinationId: 389,
        requestedBy: 1,
        analysisType: 'CCTA',
        status: 'SUCCEEDED',
        requestedAt: DateTime(2026, 9, 1, 10, 22, 19),
        completedAt: DateTime(2026, 9, 1, 10, 22, 19),
        patientName: '김OO',
        patientMeta: '68세 · 남',
      ),

      AiAnalysisUiModel(
        id: 452,
        examinationId: 638,
        requestedBy: 1,
        analysisType: 'CCTA',
        status: 'SUCCEEDED',
        requestedAt: DateTime(2026, 9, 1, 10, 22, 19),
        completedAt: DateTime(2026, 9, 1, 10, 22, 19),
        patientName: '박OO',
        patientMeta: '59세 · 여',
      ),

      AiAnalysisUiModel(
        id: 451,
        examinationId: 592,
        requestedBy: 1,
        analysisType: 'CCTA',
        status: 'SUCCEEDED',
        requestedAt: DateTime(2026, 9, 1, 10, 22, 19),
        completedAt: DateTime(2026, 9, 1, 10, 22, 19),
        patientName: '이OO',
        patientMeta: '65세 · 남',
      ),

      AiAnalysisUiModel(
        id: 9001,
        examinationId: 2005,
        requestedBy: 3,
        analysisType: 'ANGIO_2D',
        status: 'RUNNING',
        requestedAt: DateTime(2026, 9, 13, 17, 35),
        completedAt: null,
        patientName: '최OO',
        patientMeta: '71세 · 남',
        isDemo: true,
      ),

      AiAnalysisUiModel(
        id: 9002,
        examinationId: 2004,
        requestedBy: 3,
        analysisType: 'LAB',
        status: 'FAILED',
        requestedAt: DateTime(2026, 9, 13, 17, 20),
        completedAt: DateTime(2026, 9, 13, 17, 21),
        patientName: '정OO',
        patientMeta: '59세 · 여',
        isDemo: true,
      ),
    ];
  }

  // ============================================================
  // STEP 8. Inputs
  // ============================================================

  List<AiInputUiModel> _buildInputs() {
    return const [
      AiInputUiModel(
        id: 453,
        analysisId: 453,
        inputType: 'FILE_ASSET',
        examinationResultId: null,
        imagingStudyId: null,
        imagingSeriesId: null,
        fileAssetId: 54983,
        validationStatus: 'VALID',
        validationMessage: null,
        sourceLabel: 'COCA · 157.xml',
      ),

      AiInputUiModel(
        id: 9001,
        analysisId: 9001,
        inputType: 'IMAGING_STUDY',
        examinationResultId: null,
        imagingStudyId: 2001,
        imagingSeriesId: null,
        fileAssetId: null,
        validationStatus: 'VALID',
        validationMessage: null,
        sourceLabel: '2D 관상동맥 혈관조영술',
      ),

      AiInputUiModel(
        id: 9002,
        analysisId: 9002,
        inputType: 'EXAMINATION_RESULT',
        examinationResultId: 4,
        imagingStudyId: null,
        imagingSeriesId: null,
        fileAssetId: null,
        validationStatus: 'VALID',
        validationMessage: null,
        sourceLabel: '심혈관 혈액·임상 패널',
      ),
    ];
  }

  // ============================================================
  // STEP 9. AI Results
  // 전체 UI DEMO
  // ============================================================

  List<AiResultUiModel> _buildResults() {
    return const [
      AiResultUiModel(
        id: 101,
        analysisId: 9001,
        examinationId: 2005,
        patientName: '김OO',
        patientMeta: '68세 · 남',
        analysisType: 'ANGIO_2D',
        status: 'FINAL',
        summary: 'LAD 근위부에서 유의한 협착 의심 소견이 탐지되었습니다.',
        modelLabel: '2D Angio Detection · UI DEMO',
        detections: [
          AiDetectionUiModel(
            vessel: 'LAD',
            location: 'Proximal',
            confidence: 0.92,
            severity: 'HIGH',
          ),
        ],
        lesions: [
          AiLesionUiModel(
            vessel: 'LAD',
            segment: 'Proximal',
            stenosisPercent: 78,
            riskLevel: 'HIGH',
          ),
        ],
        segmentations: [],
        cacScore: null,
        explanation:
            'AI가 LAD 근위부 영역을 주요 판단 근거로 탐지했습니다. Grad-CAM Overlay는 영상 Viewer에서 연결될 예정입니다.',
      ),

      AiResultUiModel(
        id: 102,
        analysisId: 453,
        examinationId: 389,
        patientName: '김OO',
        patientMeta: '68세 · 남',
        analysisType: 'CCTA',
        status: 'FINAL',
        summary: '관상동맥 석회화와 혈관 분할 결과를 통합한 CCTA 분석입니다.',
        modelLabel: 'CCTA Segmentation / CAC · UI DEMO',
        detections: [],
        lesions: [],
        segmentations: [
          AiSegmentationUiModel(vessel: 'LAD', status: '완료'),
          AiSegmentationUiModel(vessel: 'LCX', status: '완료'),
          AiSegmentationUiModel(vessel: 'RCA', status: '완료'),
        ],
        cacScore: AiCacScoreUiModel(lad: 143, lcx: 52, rca: 31, total: 226),
        explanation: null,
      ),

      AiResultUiModel(
        id: 103,
        analysisId: 9003,
        examinationId: 2004,
        patientName: '김OO',
        patientMeta: '68세 · 남',
        analysisType: 'LAB',
        status: 'FINAL',
        summary: '심혈관 관련 혈액·임상 지표에서 위험 신호가 확인되었습니다.',
        modelLabel: 'Clinical Risk Model · UI DEMO',
        detections: [],
        lesions: [],
        segmentations: [],
        cacScore: null,
        explanation: null,
      ),
    ];
  }

  // ============================================================
  // STEP 10. CDSS
  //
  // 실제 API 조회는 [].
  // UI 확인을 위한 DEMO Assessment.
  // ============================================================

  List<CdssAssessmentUiModel> _buildAssessments() {
    return const [
      CdssAssessmentUiModel(
        id: 1,
        patientId: 1629,
        encounterId: 1213,
        patientName: '김OO',
        patientMeta: '68세 · 남',
        aiResultIds: [101, 102, 103],
        rulesetVersion: 'DEV_RULESET_V1',
        riskLevel: 'HIGH',
        summary: '영상 AI와 임상 결과를 종합했을 때 관상동맥 질환 위험이 높은 상태로 평가됩니다.',
        riskComponents: [
          CdssRiskComponentUiModel(
            title: 'LAD 협착',
            value: '78%',
            level: 'HIGH',
            description: '2D 혈관조영 AI에서 LAD 근위부 협착이 탐지되었습니다.',
          ),
          CdssRiskComponentUiModel(
            title: 'CAC Score',
            value: '226',
            level: 'MODERATE',
            description: 'CCTA 기반 석회화 분석 결과입니다.',
          ),
          CdssRiskComponentUiModel(
            title: '혈액·임상 위험',
            value: 'Elevated',
            level: 'MODERATE',
            description: '심혈관 관련 임상 지표에서 위험 신호가 확인되었습니다.',
          ),
        ],
        sources: [
          CdssSourceUiModel(
            sourceType: '2D',
            title: '2D 혈관조영 AI',
            description: 'LAD 근위부 협착 탐지 및 병변 중증도 결과를 반영했습니다.',
          ),
          CdssSourceUiModel(
            sourceType: '3D',
            title: 'CCTA / CAC',
            description: '관상동맥 분할 및 CAC Score 결과를 반영했습니다.',
          ),
          CdssSourceUiModel(
            sourceType: 'LAB',
            title: '혈액·임상 검사',
            description: '심혈관 관련 혈액검사 및 임상 지표를 반영했습니다.',
          ),
        ],
        recommendations: [
          CdssRecommendationUiModel(
            title: '전문의 검토',
            description: 'AI 결과와 원본 영상을 함께 확인하여 최종 임상 판단을 수행합니다.',
            priority: 'HIGH',
          ),
          CdssRecommendationUiModel(
            title: '추가 평가 고려',
            description: '환자의 증상과 임상 상태를 고려하여 추가 심혈관 평가 필요성을 검토합니다.',
            priority: 'MODERATE',
          ),
        ],
      ),
    ];
  }
}
