import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/auth/auth_provider.dart';
import '../data/services/ai_analysis_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'ai_ui_models.dart';
import 'clinical_ai_input_dialog.dart';
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

  List<AiAnalysisUiModel> _analyses = [];
  List<AiInputUiModel> _inputs = [];

  final List<AiJobUiModel> _jobs = [];
  final List<AiAnalysisResultSummaryUiModel> _analysisResultSummaries = [];
  final Map<int, AiAnalysisPatientContextRecord> _patientContextCache = {};

  bool _isAnalysisLoading = true;
  String? _analysisLoadError;

  List<AiResultUiModel> _results = [];

  late final List<CdssAssessmentUiModel> _assessments;

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _assessments = _buildAssessments();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyses();
    });
  }

  // ============================================================
  // STEP 3. 실제 AI 분석 목록 조회
  // GET /api/ai-analyses/
  // ============================================================

  // ============================================================
  // STEP 3. 실제 AI 분석 목록 조회
  // GET /api/ai-analyses/
  // ============================================================

  Future<void> _loadAnalyses() async {
    setState(() {
      _isAnalysisLoading = true;
      _analysisLoadError = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      final records = await service.fetchAnalyses();

      // ==========================================================
      // 실제 Analysis 목록
      // ==========================================================

      final analyses = records.map((record) {
        return AiAnalysisUiModel(
          id: record.id,
          examinationId: record.examinationId,
          requestedBy: record.requestedBy,
          analysisType: record.analysisType,
          status: record.status,
          requestedAt: record.requestedAt,
          completedAt: record.completedAt,
          patientName: '검사 #${record.examinationId}',
          patientMeta: '환자 정보 연결 예정',
          isDemo: false,
        );
      }).toList();

      // ==========================================================
      // AI Result Placeholder
      // SUCCEEDED만 결과 탭에 노출
      // 실제 Result는 선택 시 Lazy Load
      // ==========================================================

      final resultPlaceholders = analyses
          .where((analysis) => analysis.status == 'SUCCEEDED')
          .map(
            (analysis) => AiResultUiModel(
              id: 0,
              analysisId: analysis.id,
              examinationId: analysis.examinationId,
              patientName: analysis.patientName,
              patientMeta: analysis.patientMeta,
              analysisType: analysis.analysisType,
              status: 'READY',
              summary: '결과를 선택하면 실제 AI 결과를 불러옵니다.',
              modelLabel: '모델 정보 조회 전',
              detections: const [],
              lesions: const [],
              segmentations: const [],
              cacScore: null,
              explanation: null,
              isDemo: false,
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _analyses = analyses;
        _results = resultPlaceholders;
        _inputs = [];

        _isAnalysisLoading = false;
        _analysisLoadError = null;
      });

      if (analyses.isNotEmpty) {
        await _loadAnalysisDetail(analyses.first);
      }

      debugPrint(
        '[AI ANALYSIS] 실제 분석 목록 '
        '${analyses.length}건 조회 완료 / '
        '결과 후보 ${resultPlaceholders.length}건',
      );
    } catch (error) {
      debugPrint('[AI ANALYSIS] 실제 분석 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _analyses = [];
        _results = [];
        _inputs = [];

        _isAnalysisLoading = false;
        _analysisLoadError = error.toString();
      });
    }
  }

  // ============================================================
  // STEP. 실제 AI Result 조회
  //
  // Analysis Detail
  // → Job / Result
  // → Patient
  // → CCTA인 경우 Segmentation
  // ============================================================

  Future<void> _loadResultDetail(AiResultUiModel selectedResult) async {
    debugPrint(
      '[AI RESULT] 상세 조회 시작: '
      'analysisId=${selectedResult.analysisId}, '
      'examinationId=${selectedResult.examinationId}',
    );

    final analysisIndex = _analyses.indexWhere(
      (item) => item.id == selectedResult.analysisId,
    );

    if (analysisIndex < 0) {
      debugPrint(
        '[AI RESULT] Analysis를 찾지 못함: '
        'analysisId=${selectedResult.analysisId}',
      );
      return;
    }

    final analysis = _analyses[analysisIndex];

    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      // ----------------------------------------------------------
      // 1. Analysis Detail
      // ----------------------------------------------------------

      final detail = await service.fetchAnalysisDetail(analysis.id);

      if (detail.results.isEmpty) {
        _showMessage('생성된 AI 결과가 없습니다.');
        return;
      }

      // ----------------------------------------------------------
      // 2. 최신 Job
      // ----------------------------------------------------------

      AiAnalysisJobRecord? latestJob;

      for (final job in detail.jobs) {
        if (latestJob == null || job.id > latestJob.id) {
          latestJob = job;
        }
      }

      // ----------------------------------------------------------
      // 3. 최신 Result
      // ----------------------------------------------------------

      AiAnalysisResultRecord? latestResult;

      for (final result in detail.results) {
        if (latestResult == null || result.id > latestResult.id) {
          latestResult = result;
        }
      }

      if (latestResult == null) {
        _showMessage('생성된 AI 결과가 없습니다.');
        return;
      }

      // ----------------------------------------------------------
      // 4. 환자 정보
      // 기존 Cache 사용
      // ----------------------------------------------------------

      await _loadAnalysisPatientContext(analysis);

      if (!mounted) {
        return;
      }

      final refreshedAnalysisIndex = _analyses.indexWhere(
        (item) => item.id == analysis.id,
      );

      final refreshedAnalysis = refreshedAnalysisIndex >= 0
          ? _analyses[refreshedAnalysisIndex]
          : analysis;

      // ----------------------------------------------------------
      // 5. CCTA Segmentation
      // ----------------------------------------------------------

      List<AiResultSegmentationUiModel> segmentationDetails = [];

      if (analysis.analysisType == 'CCTA') {
        final segmentationRecords = await service.fetchResultSegmentations(
          latestResult.id,
        );

        segmentationDetails = segmentationRecords.map((item) {
          return AiResultSegmentationUiModel(
            structureName: item.structureName,
            maskFileAssetId: item.maskFileAssetId,
            meshFileAssetId: item.meshFileAssetId,
            volumeMm3: item.volumeMm3,
            metricsJson: item.metricsJson,
          );
        }).toList();
      }

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // 6. 실제 Result UI Model 생성
      // ----------------------------------------------------------

      final actualResult = AiResultUiModel(
        id: latestResult.id,
        analysisId: analysis.id,
        examinationId: analysis.examinationId,
        patientName: refreshedAnalysis.patientName,
        patientMeta: refreshedAnalysis.patientMeta,
        analysisType: analysis.analysisType,
        status: latestResult.status,
        summary: latestResult.summaryText,
        modelLabel: latestJob == null
            ? '모델 버전 정보 없음'
            : 'Model Version #${latestJob.aiModelVersion}',
        detections: const [],
        lesions: const [],
        segmentations: const [],
        cacScore: null,
        explanation: null,

        resultType: latestResult.resultType,
        confidence: latestResult.confidence,
        resultJson: latestResult.resultJson,
        modelVersionId: latestJob?.aiModelVersion,
        segmentationDetails: segmentationDetails,

        isDemo: false,
      );

      // ----------------------------------------------------------
      // 7. 기존 Placeholder 교체
      // ----------------------------------------------------------

      final resultIndex = _results.indexWhere(
        (item) => item.analysisId == analysis.id,
      );

      if (resultIndex < 0) {
        return;
      }

      setState(() {
        _results[resultIndex] = actualResult;
      });

      debugPrint(
        '[AI RESULT] 상세 조회 완료: '
        'analysisId=${analysis.id}, '
        'resultId=${latestResult.id}, '
        'type=${analysis.analysisType}, '
        'segmentations=${segmentationDetails.length}',
      );
    } catch (error) {
      debugPrint(
        '[AI RESULT] 상세 조회 실패: '
        'analysisId=${analysis.id}, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('AI 결과를 불러오지 못했습니다.');
    }
  }

  // ============================================================
  // AI 분석 연결 환자 조회
  // 선택된 분석만 조회 + Examination 기준 Cache
  // ============================================================

  Future<void> _loadAnalysisPatientContext(AiAnalysisUiModel analysis) async {
    try {
      AiAnalysisPatientContextRecord contextRecord;

      final cached = _patientContextCache[analysis.examinationId];

      if (cached != null) {
        contextRecord = cached;
      } else {
        final auth = context.read<AuthProvider>();

        final service = AiAnalysisService(
          apiClient: auth.authService.apiClient,
        );

        contextRecord = await service.fetchPatientContext(
          analysis.examinationId,
        );

        _patientContextCache[analysis.examinationId] = contextRecord;
      }

      if (!mounted) {
        return;
      }

      final index = _analyses.indexWhere((item) => item.id == analysis.id);

      if (index < 0) {
        return;
      }

      setState(() {
        _analyses[index] = _analyses[index].copyWith(
          patientName: contextRecord.name,
          patientMeta: _buildPatientMeta(
            birthDate: contextRecord.birthDate,
            gender: contextRecord.gender,
          ),
        );
      });

      debugPrint(
        '[AI ANALYSIS] 환자 연결 완료: '
        'analysisId=${analysis.id}, '
        'patientId=${contextRecord.patientId}, '
        'name=${contextRecord.name}',
      );
    } catch (error) {
      debugPrint(
        '[AI ANALYSIS] 환자 연결 실패: '
        'analysisId=${analysis.id}, '
        'examinationId=${analysis.examinationId}, '
        'error=$error',
      );
    }
  }

  // ============================================================
  // STEP 4. 실제 AI 분석 상세 조회
  // GET /api/ai-analyses/{analysisId}/
  // ============================================================

  Future<void> _loadAnalysisDetail(AiAnalysisUiModel analysis) async {
    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      final detail = await service.fetchAnalysisDetail(analysis.id);

      final inputs = detail.inputs.map((input) {
        return AiInputUiModel(
          id: input.id,
          analysisId: input.analysisId,
          inputType: input.inputType,
          examinationResultId: input.examinationResultId,
          imagingStudyId: input.imagingStudyId,
          imagingSeriesId: input.imagingSeriesId,
          fileAssetId: input.fileAssetId,
          validationStatus: input.validationStatus,
          validationMessage: input.validationMessage,
          sourceLabel: _buildInputSourceLabel(input),
        );
      }).toList();

      final jobs = detail.jobs.map((job) {
        return AiJobUiModel(
          id: job.id,
          analysisId: job.analysisId,
          aiModelVersion: job.aiModelVersion,
          status: job.status,
          progressPercent: job.progressPercent,
          retryCount: job.retryCount,
          errorCode: job.errorCode,
          errorMessage: job.errorMessage,
          workerId: job.workerId,
          queuedAt: job.queuedAt,
          startedAt: job.startedAt,
          finishedAt: job.finishedAt,
        );
      }).toList();

      final resultSummaries = detail.results.map((result) {
        return AiAnalysisResultSummaryUiModel(
          id: result.id,
          analysisId: analysis.id,
          jobId: result.jobId,
          resultType: result.resultType,
          summaryText: result.summaryText,
          status: result.status,
          confidence: result.confidence,
          resultJson: result.resultJson,
        );
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        // ==========================================================
        // Backend 최신 Analysis 상태 반영
        // ==========================================================

        final analysisIndex = _analyses.indexWhere(
          (item) => item.id == analysis.id,
        );

        if (analysisIndex >= 0) {
          final current = _analyses[analysisIndex];
          final refreshed = detail.analysis;

          _analyses[analysisIndex] = AiAnalysisUiModel(
            id: refreshed.id,
            examinationId: refreshed.examinationId,
            requestedBy: refreshed.requestedBy,
            analysisType: refreshed.analysisType,
            status: refreshed.status,
            requestedAt: refreshed.requestedAt,
            completedAt: refreshed.completedAt,
            patientName: current.patientName,
            patientMeta: current.patientMeta,
            isDemo: false,
          );
        }

        // ==========================================================
        // Input / Job / Result 갱신
        // ==========================================================

        _inputs.removeWhere((item) => item.analysisId == analysis.id);

        _jobs.removeWhere((item) => item.analysisId == analysis.id);

        _analysisResultSummaries.removeWhere(
          (item) => item.analysisId == analysis.id,
        );

        _inputs.addAll(inputs);
        _jobs.addAll(jobs);
        _analysisResultSummaries.addAll(resultSummaries);
      });

      debugPrint(
        '[AI ANALYSIS] 상세 조회 완료: '
        'analysisId=${analysis.id}, '
        'inputs=${detail.inputs.length}, '
        'jobs=${detail.jobs.length}, '
        'results=${detail.results.length}',
      );

      // ========================================================
      // 선택된 분석의 실제 환자 정보 연결
      // ========================================================

      await _loadAnalysisPatientContext(analysis);
    } catch (error) {
      debugPrint(
        '[AI ANALYSIS] 상세 조회 실패: '
        'analysisId=${analysis.id}, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('AI 분석 상세 정보를 불러오지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 5. AI Input 표시명
  // ============================================================

  String _buildPatientMeta({
    required String birthDate,
    required String gender,
  }) {
    final birth = DateTime.tryParse(birthDate);

    String ageLabel = '나이 미상';

    if (birth != null) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 9));

      var age = now.year - birth.year;

      final birthdayPassed =
          now.month > birth.month ||
          (now.month == birth.month && now.day >= birth.day);

      if (!birthdayPassed) {
        age -= 1;
      }

      ageLabel = '$age세';
    }

    final normalizedGender = gender.trim().toUpperCase();

    final genderLabel = switch (normalizedGender) {
      'M' || 'MALE' => '남',
      'F' || 'FEMALE' => '여',
      _ => gender.isEmpty ? '성별 미상' : gender,
    };

    return '$ageLabel · $genderLabel';
  }

  String _buildInputSourceLabel(AiAnalysisInputRecord input) {
    switch (input.inputType.toUpperCase()) {
      case 'CLINICAL_DATA':
        final variableCount = input.inputSnapshot.length;

        if (variableCount > 0) {
          return '임상 데이터 스냅샷 · $variableCount개 변수';
        }

        return '임상 데이터';

      case 'EXAMINATION_RESULT':
        if (input.examinationResultId != null) {
          return '검사 결과 #${input.examinationResultId}';
        }

        return '검사 결과';

      case 'IMAGING_STUDY':
        if (input.imagingStudyId != null) {
          return 'Imaging Study #${input.imagingStudyId}';
        }

        return '영상 검사';

      case 'IMAGING_SERIES':
        if (input.imagingSeriesId != null) {
          return 'Imaging Series #${input.imagingSeriesId}';
        }

        return '영상 Series';

      case 'FILE_ASSET':
        if (input.fileAssetId != null) {
          return 'File Asset #${input.fileAssetId}';
        }

        return '파일 데이터';

      default:
        return input.inputType;
    }
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
        if (_isAnalysisLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_analysisLoadError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 10),
                Text(
                  'AI 분석 목록을 불러오지 못했습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _analysisLoadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadAnalyses,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        return AiAnalysisPanel(
          analyses: _analyses,
          inputs: _inputs,
          jobs: _jobs,
          resultSummaries: _analysisResultSummaries,
          onAnalysisSelected: _loadAnalysisDetail,
          onCreateAnalysis: _openCreateAnalysisDialog,
          onRetry: _retryAnalysis,
          onCancel: _cancelAnalysis,
        );

      case AiSection.results:
        return AiResultPanel(
          results: _results,
          onResultSelected: _loadResultDetail,
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
  // STEP. AI 분석 실제 재시도
  // POST /api/ai-analyses/{analysisId}/retry/
  // ============================================================

  Future<void> _retryAnalysis(AiAnalysisUiModel analysis) async {
    final failedJobIds = _jobs
        .where((job) => job.analysisId == analysis.id && job.status == 'FAILED')
        .map((job) => job.id)
        .toList();

    if (failedJobIds.isEmpty) {
      _showMessage('재시도할 실패 작업이 없습니다.');
      return;
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      await service.retryAnalysis(
        analysisId: analysis.id,
        failedJobIds: failedJobIds,
      );

      if (!mounted) {
        return;
      }

      _showMessage('AI 분석 재시도를 요청했습니다.');

      // Backend 최신 상태 다시 조회
      await _loadAnalysisDetail(analysis);

      debugPrint(
        '[AI ANALYSIS] 재시도 요청 완료: '
        'analysisId=${analysis.id}, '
        'failedJobIds=$failedJobIds',
      );
    } catch (error) {
      debugPrint(
        '[AI ANALYSIS] 재시도 요청 실패: '
        'analysisId=${analysis.id}, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('AI 분석 재시도에 실패했습니다.');
    }
  }

  // ============================================================
  // STEP. AI 분석 취소 사유 Dialog
  // ============================================================

  Future<String?> _showCancelReasonDialog() async {
    String reason = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSubmit = reason.trim().isNotEmpty;

            return AlertDialog(
              title: const Text('AI 분석 취소'),
              content: SizedBox(
                width: 420,
                child: TextField(
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (value) {
                    setDialogState(() {
                      reason = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: '취소 사유',
                    hintText: '분석을 취소하는 사유를 입력해주세요.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('닫기'),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () {
                          Navigator.of(dialogContext).pop(reason.trim());
                        }
                      : null,
                  child: const Text('분석 취소'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STEP. AI 분석 실제 취소
  // POST /api/ai-analyses/{analysisId}/cancel/
  // ============================================================

  Future<void> _cancelAnalysis(AiAnalysisUiModel analysis) async {
    final reason = await _showCancelReasonDialog();

    if (!mounted) {
      return;
    }

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      await service.cancelAnalysis(analysisId: analysis.id, reason: reason);

      if (!mounted) {
        return;
      }

      _showMessage('AI 분석을 취소했습니다.');

      // Backend 최신 상태 다시 조회
      await _loadAnalysisDetail(analysis);

      debugPrint(
        '[AI ANALYSIS] 취소 완료: '
        'analysisId=${analysis.id}',
      );
    } catch (error) {
      debugPrint(
        '[AI ANALYSIS] 취소 실패: '
        'analysisId=${analysis.id}, '
        'error=$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage('AI 분석 취소에 실패했습니다.');
    }
  }

  // ============================================================
  // STEP. AI 분석 요청 Dialog
  //
  // 1차 연결:
  // CLINICAL 실제 API 요청 검증
  //
  // CCTA / ANGIO_2D는 입력 영상 연결 확인 후 확장
  // ============================================================

  Future<void> _openCreateAnalysisDialog() async {
    String examinationIdText = '';
    var isSubmitting = false;

    final requested = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('AI 분석 요청'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '혈액·임상 AI 분석',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '검사 결과가 존재하는 Examination을 선택해 '
                      'Clinical AI 분석을 요청합니다.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        examinationIdText = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Examination ID',
                        hintText: '예: 1667',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '현재 모델 버전은 Backend 권한 구조 때문에 '
                        'Clinical 활성 버전 #2를 임시 사용합니다.\n'
                        '최종적으로는 Backend에서 ACTIVE 모델을 '
                        '자동 선택하도록 변경할 예정입니다.',
                        style: TextStyle(fontSize: 9.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('취소'),
                ),

                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final examinationId = int.tryParse(
                            examinationIdText.trim(),
                          );

                          if (examinationId == null || examinationId <= 0) {
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _debugClinicalInputPrefill(examinationId);

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop(false);
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('분석 요청'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || requested != true) {
      return;
    }

    _showMessage('AI 분석 요청을 등록했습니다.');

    await _loadAnalyses();
  }

  // ============================================================
  // TEMP. Clinical AI 자동 입력 데이터 확인
  // 실제 POST 전 prefill 검증용
  // ============================================================

  Future<void> _debugClinicalInputPrefill(int examinationId) async {
    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      final prefill = await service.fetchClinicalInputPrefill(examinationId);

      if (!mounted) {
        return;
      }

      final clinicalInput = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ClinicalAiInputDialog(
            examinationId: examinationId,
            prefill: prefill,
          );
        },
      );

      if (clinicalInput == null) {
        return;
      }

      debugPrint(
        '[AI CLINICAL INPUT READY] '
        'count=${clinicalInput.length}, '
        'data=$clinicalInput',
        wrapWidth: 1024,
      );

      debugPrint(
        '[AI CLINICAL PREFILL CHECK] '
        'examinationId=$examinationId, '
        'patientId=${prefill.patient.patientId}, '
        'encounterId=${prefill.patient.encounterId}, '
        'resultId=${prefill.examinationResultId}, '
        'filled=${prefill.values.length}/54',
      );

      if (mounted) {
        _showMessage('Clinical 자동 입력 ${prefill.values.length}/54개를 확인했습니다.');
      }
    } catch (error) {
      debugPrint(
        '[AI CLINICAL PREFILL ERROR] '
        'examinationId=$examinationId, '
        'error=$error',
      );

      if (mounted) {
        _showMessage('Clinical 입력 데이터를 불러오지 못했습니다.');
      }

      rethrow;
    }
  }

  // ============================================================
  // 실제 Clinical AI 분석 요청
  // ============================================================

  // TEMP: prefill 검증 후 다시 연결 예정
  // ignore: unused_element
  Future<void> _requestClinicalAnalysis(int examinationId) async {
    try {
      final auth = context.read<AuthProvider>();

      final service = AiAnalysisService(apiClient: auth.authService.apiClient);

      // ----------------------------------------------------------
      // 1. 검사 결과 확인
      // ----------------------------------------------------------

      final examinationResultId = await service.fetchLatestExaminationResultId(
        examinationId,
      );

      if (examinationResultId == null) {
        if (mounted) {
          _showMessage('이 검사에는 AI 분석에 사용할 결과가 없습니다.');
        }

        throw StateError('Examination Result 없음');
      }

      // ----------------------------------------------------------
      // 2. 실제 분석 요청
      //
      // TEMP:
      // doctor 계정에서 AI Model 관리 API 접근 불가
      // 현재 확인된 Clinical Model Version #2 사용
      // ----------------------------------------------------------

      await service.createAnalysis(
        examinationId: examinationId,
        analysisType: 'CLINICAL',
        modelVersionIds: const [2],
        inputRefs: [
          {
            'input_type': 'CLINICAL_DATA',
            'examination_result_id': examinationResultId,
            'imaging_study_id': null,
            'imaging_series_id': null,
            'file_asset_id': null,
            'input_snapshot_json': null,
          },
        ],
      );

      debugPrint(
        '[AI ANALYSIS] CLINICAL 요청 완료: '
        'examinationId=$examinationId, '
        'examinationResultId=$examinationResultId, '
        'modelVersionId=2',
      );
    } on DioException catch (error) {
      debugPrint(
        '[AI ANALYSIS] CLINICAL 요청 실패 응답: '
        'status=${error.response?.statusCode}, '
        'data=${error.response?.data}',
      );

      debugPrint(
        '[AI ANALYSIS] CLINICAL 요청 정보: '
        'examinationId=$examinationId, '
        'analysisType=CLINICAL, '
        'modelVersionIds=[2]',
      );

      if (mounted) {
        _showMessage('AI 분석 요청에 실패했습니다.');
      }

      rethrow;
    } catch (error) {
      debugPrint(
        '[AI ANALYSIS] CLINICAL 요청 실패: '
        'examinationId=$examinationId, '
        'error=$error',
      );

      if (mounted) {
        _showMessage('AI 분석 요청에 실패했습니다.');
      }

      rethrow;
    }
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
