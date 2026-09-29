import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_context.dart';
import '../../../core/widgets/app_shell.dart';
import '../../ai/presentation/ai_ui_models.dart';
import '../data/services/imaging_service.dart';

import 'ccta_viewer_page.dart';
import 'imaging_ui_models.dart';

import 'widgets/imaging_compare_view.dart';
import 'widgets/imaging_info_panel.dart';
import 'widgets/imaging_study_panel.dart';
import 'widgets/imaging_viewer_controls.dart';
import 'widgets/imaging_viewer_panel.dart';

// ============================================================
// STEP 1. Imaging Page
// ============================================================

class ImagingPage extends StatefulWidget {
  final AiResultUiModel? initialCctaResult;

  const ImagingPage({super.key, this.initialCctaResult});

  @override
  State<ImagingPage> createState() => _ImagingPageState();
}

class _ImagingPageState extends State<ImagingPage> {
  List<ImagingStudyUiModel> _studies = <ImagingStudyUiModel>[];
  List<ImagingSeriesUiModel> _series = <ImagingSeriesUiModel>[];

  bool _isLoadingStudies = true;
  bool _isLoadingSeries = false;
  String? _loadError;

  int? _selectedStudyId;
  int? _selectedSeriesId;
  int _currentIndex = 0;

  bool _isPlaying = false;

  double _playbackSpeed = 1.0;
  double _zoom = 1.0;

  bool _panEnabled = false;

  ImagingViewerMode _viewerMode = ImagingViewerMode.slice2d;

  bool _segmentationEnabled = false;
  bool _cacEnabled = false;
  bool _bboxEnabled = false;
  bool _heatmapEnabled = false;
  bool _compareMode = false;

  AiResultUiModel? _activeCctaResult;

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _activeCctaResult = widget.initialCctaResult;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImagingData();
    });
  }

  @override
  void didUpdateWidget(covariant ImagingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialCctaResult != widget.initialCctaResult) {
      _activeCctaResult = widget.initialCctaResult;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImagingData();
      });
    }
  }

  // ============================================================
  // STEP 3. 실제 영상 목록 조회
  // ============================================================

  Future<void> _loadImagingData() async {
    if (mounted) {
      setState(() {
        _isLoadingStudies = true;
        _loadError = null;
        _compareMode = false;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = ImagingService(apiClient: auth.authService.apiClient);

      final cctaResult = widget.initialCctaResult;

      List<ImagingStudyUiModel> targetStudies = <ImagingStudyUiModel>[];

      Object? targetError;

      if (cctaResult != null) {
        try {
          targetStudies = await service.fetchStudies(
            examinationId: cctaResult.examinationId,
          );
        } catch (error) {
          targetError = error;

          debugPrint(
            '[IMAGING] CCTA 검사 Study 조회 실패: '
            'examinationId=${cctaResult.examinationId}, '
            'error=$error',
          );
        }
      }

      List<ImagingStudyUiModel> recentStudies = <ImagingStudyUiModel>[];

      Object? recentError;

      try {
        recentStudies = await service.fetchStudies();
      } catch (error) {
        recentError = error;

        debugPrint('[IMAGING] 전체 Study 조회 실패: $error');
      }

      final mergedById = <int, ImagingStudyUiModel>{};

      for (final study in recentStudies) {
        mergedById[study.id] = study;
      }

      for (final study in targetStudies) {
        mergedById[study.id] = study;
      }

      final studies = mergedById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (studies.isEmpty) {
        final error = targetError ?? recentError;

        if (error != null) {
          throw error;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _studies = <ImagingStudyUiModel>[];
          _series = <ImagingSeriesUiModel>[];
          _selectedStudyId = null;
          _selectedSeriesId = null;
          _isLoadingStudies = false;
          _isLoadingSeries = false;
          _loadError = null;
        });

        return;
      }

      ImagingStudyUiModel selectedStudy = studies.first;

      if (cctaResult != null) {
        for (final study in studies) {
          if (study.examinationId == cctaResult.examinationId) {
            selectedStudy = study;
            break;
          }
        }
      }

      List<ImagingSeriesUiModel> series;

      try {
        series = await service.fetchSeries(selectedStudy.id);
      } catch (error) {
        debugPrint(
          '[IMAGING] 초기 Series 조회 실패: '
          'studyId=${selectedStudy.id}, '
          'error=$error',
        );

        series = <ImagingSeriesUiModel>[];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _studies = studies;
        _series = series;

        _selectedStudyId = selectedStudy.id;
        _selectedSeriesId = series.isEmpty ? null : series.first.id;

        _currentIndex = 0;
        _isPlaying = false;
        _zoom = 1.0;
        _panEnabled = false;

        _viewerMode = ImagingViewerMode.slice2d;
        _segmentationEnabled = false;
        _cacEnabled = false;
        _bboxEnabled = false;
        _heatmapEnabled = false;

        _activeCctaResult =
            cctaResult != null &&
                selectedStudy.examinationId == cctaResult.examinationId
            ? cctaResult
            : null;

        _isLoadingStudies = false;
        _isLoadingSeries = false;
        _loadError = null;
      });

      debugPrint(
        '[IMAGING] 실제 영상 목록 조회 완료: '
        'studies=${studies.length}, '
        'selectedStudy=${selectedStudy.id}, '
        'selectedExam=${selectedStudy.examinationId}, '
        'series=${series.length}, '
        'cctaLinked=${_activeCctaResult != null}',
      );
    } catch (error) {
      debugPrint('[IMAGING] 영상 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _studies = <ImagingStudyUiModel>[];
        _series = <ImagingSeriesUiModel>[];
        _selectedStudyId = null;
        _selectedSeriesId = null;
        _isLoadingStudies = false;
        _isLoadingSeries = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadSeriesForStudy(int studyId) async {
    if (mounted) {
      setState(() {
        _isLoadingSeries = true;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final service = ImagingService(apiClient: auth.authService.apiClient);

      final series = await service.fetchSeries(studyId);

      if (!mounted || _selectedStudyId != studyId) {
        return;
      }

      setState(() {
        _series = series;
        _selectedSeriesId = series.isEmpty ? null : series.first.id;
        _currentIndex = 0;
        _isPlaying = false;
        _isLoadingSeries = false;
      });
    } catch (error) {
      debugPrint(
        '[IMAGING] Series 조회 실패: '
        'studyId=$studyId, '
        'error=$error',
      );

      if (!mounted || _selectedStudyId != studyId) {
        return;
      }

      setState(() {
        _series = <ImagingSeriesUiModel>[];
        _selectedSeriesId = null;
        _currentIndex = 0;
        _isPlaying = false;
        _isLoadingSeries = false;
      });

      _showMessage('선택한 Study의 Series를 불러오지 못했습니다.');
    }
  }

  // ============================================================
  // STEP 4. Selected Data
  // ============================================================

  ImagingStudyUiModel get _selectedStudy {
    return _studies.firstWhere(
      (study) => study.id == _selectedStudyId,

      orElse: () => _studies.first,
    );
  }

  ImagingSeriesUiModel? get _selectedSeries {
    for (final series in _series) {
      if (series.id == _selectedSeriesId) {
        return series;
      }
    }

    return null;
  }

  int get _totalCount {
    final selectedSeries = _selectedSeries;

    if (selectedSeries != null) {
      return selectedSeries.instanceCount <= 0
          ? 1
          : selectedSeries.instanceCount;
    }

    return _selectedStudy.instanceCount <= 0 ? 1 : _selectedStudy.instanceCount;
  }

  ImagingStudyUiModel? get _comparisonCandidate {
    for (final study in _studies) {
      if (study.id != _selectedStudy.id &&
          study.modality == _selectedStudy.modality &&
          !study.isDemo) {
        return study;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 4. Study Select
  // ============================================================

  void _selectStudy(ImagingStudyUiModel study) {
    final cctaResult = widget.initialCctaResult;

    setState(() {
      _selectedStudyId = study.id;
      _selectedSeriesId = null;

      _currentIndex = 0;
      _viewerMode = ImagingViewerMode.slice2d;

      _isPlaying = false;
      _zoom = 1.0;
      _panEnabled = false;

      _segmentationEnabled = false;
      _cacEnabled = false;
      _bboxEnabled = false;
      _heatmapEnabled = false;

      _compareMode = false;

      _activeCctaResult =
          cctaResult != null && study.examinationId == cctaResult.examinationId
          ? cctaResult
          : null;
    });

    _loadSeriesForStudy(study.id);
  }

  void _selectSeries(ImagingSeriesUiModel series) {
    setState(() {
      _selectedSeriesId = series.id;
      _currentIndex = 0;
      _isPlaying = false;
    });
  }

  // ============================================================
  // STEP 5. Frame / Slice
  // ============================================================

  void _previous() {
    if (_currentIndex <= 0) {
      return;
    }

    setState(() {
      _currentIndex -= 1;
    });
  }

  void _next() {
    if (_currentIndex >= _totalCount - 1) {
      return;
    }

    setState(() {
      _currentIndex += 1;
    });
  }

  void _changeIndex(int index) {
    setState(() {
      _currentIndex = index.clamp(0, _totalCount - 1);
    });
  }

  // ============================================================
  // STEP 6. Viewer Controls
  // ============================================================

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _stop() {
    setState(() {
      _isPlaying = false;

      _currentIndex = 0;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.1).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.1).clamp(0.5, 3.0);
    });
  }

  void _fit() {
    setState(() {
      _zoom = 1.0;

      _panEnabled = false;
    });
  }

  void _resetViewer() {
    setState(() {
      _currentIndex = 0;

      _zoom = 1.0;

      _panEnabled = false;

      _isPlaying = false;
    });
  }

  // ============================================================
  // STEP 7. Mock Original Viewer
  // 실제 연결 시 viewer-token API 사용
  // ============================================================

  void _openOriginalViewer() {
    _showMessage('원본 Orthanc Viewer는 실제 viewer-token API 연결 단계에서 구현합니다.');
  }

  // ============================================================
  // STEP 8. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '영상',
      selectedIndex: 4,
      body: Material(
        color: context.appBackground,
        child: Container(
          color: context.appBackground,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _buildPageBody(),
        ),
      ),
    );
  }

  Widget _buildPageBody() {
    if (_isLoadingStudies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studies.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _loadError == null
                    ? Icons.image_not_supported_outlined
                    : Icons.error_outline_rounded,
                size: 34,
                color: context.appTextSecondary,
              ),

              const SizedBox(height: 12),

              Text(
                _loadError == null
                    ? '조회 가능한 의료영상이 없습니다.'
                    : '의료영상 목록을 불러오지 못했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),

              if (_loadError != null) ...[
                const SizedBox(height: 7),

                Text(
                  _loadError!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.4,
                    color: context.appTextSecondary,
                  ),
                ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: _loadImagingData,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('다시 조회'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _compareMode ? _buildCompareView() : _buildViewerWorkspace();
  }

  // ============================================================
  // STEP 9. Unified Viewer Workspace
  // ============================================================

  Widget _buildViewerWorkspace() {
    final cctaResult = _activeCctaResult;
    final study = _selectedStudy;
    final series = _selectedSeries;

    return Column(
      children: [
        _buildWorkspaceHeader(cctaResult: cctaResult, study: study),

        const SizedBox(height: 10),

        if (_isLoadingSeries) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
        ],

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // Study List
              // ==================================================
              Expanded(
                flex: 3,
                child: ImagingStudyPanel(
                  studies: _studies,
                  series: _series,
                  selectedStudyId: _selectedStudyId,
                  selectedSeriesId: _selectedSeriesId,
                  onStudySelected: _selectStudy,
                  onSeriesSelected: _selectSeries,
                ),
              ),

              const SizedBox(width: 12),

              // ==================================================
              // CCTA AI-linked Viewer
              // ==================================================
              if (cctaResult != null)
                Expanded(
                  flex: 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CctaViewerPage(result: cctaResult, embedded: true),
                  ),
                )
              else ...[
                // ================================================
                // Existing Viewer
                // ================================================
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: ImagingViewerPanel(
                          study: study,
                          series: series,
                          currentIndex: _currentIndex,
                          totalCount: _totalCount,
                          viewerMode: _viewerMode,
                          segmentationEnabled: _segmentationEnabled,
                          cacEnabled: _cacEnabled,
                          bboxEnabled: _bboxEnabled,
                          heatmapEnabled: _heatmapEnabled,
                        ),
                      ),

                      const SizedBox(height: 8),

                      ImagingViewerControls(
                        modality: study.modality,
                        currentIndex: _currentIndex,
                        totalCount: _totalCount,
                        isPlaying: _isPlaying,
                        playbackSpeed: _playbackSpeed,
                        zoom: _zoom,
                        panEnabled: _panEnabled,
                        onPrevious: _previous,
                        onNext: _next,
                        onPlayPause: _togglePlayPause,
                        onStop: _stop,
                        onIndexChanged: _changeIndex,
                        onSpeedChanged: (value) {
                          setState(() {
                            _playbackSpeed = value;
                          });
                        },
                        onZoomOut: _zoomOut,
                        onZoomIn: _zoomIn,
                        onTogglePan: () {
                          setState(() {
                            _panEnabled = !_panEnabled;
                          });
                        },
                        onFit: _fit,
                        onReset: _resetViewer,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ================================================
                // Existing Info Panel
                // ================================================
                Expanded(
                  flex: 3,
                  child: ImagingInfoPanel(
                    study: study,
                    series: series,
                    currentIndex: _currentIndex,
                    totalCount: _totalCount,
                    viewerMode: _viewerMode,
                    segmentationEnabled: _segmentationEnabled,
                    cacEnabled: _cacEnabled,
                    bboxEnabled: _bboxEnabled,
                    heatmapEnabled: _heatmapEnabled,
                    onViewerModeChanged: (mode) {
                      setState(() {
                        _viewerMode = mode;
                      });
                    },
                    onSegmentationChanged: (value) {
                      setState(() {
                        _segmentationEnabled = value;
                      });
                    },
                    onCacChanged: (value) {
                      setState(() {
                        _cacEnabled = value;
                      });
                    },
                    onBboxChanged: (value) {
                      setState(() {
                        _bboxEnabled = value;
                      });
                    },
                    onHeatmapChanged: (value) {
                      setState(() {
                        _heatmapEnabled = value;
                      });
                    },
                    onOpenOriginalViewer: _openOriginalViewer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceHeader({
    required AiResultUiModel? cctaResult,
    required ImagingStudyUiModel study,
  }) {
    final isCcta = cctaResult != null;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: context.appBorder),
          ),
          child: Icon(
            isCcta ? Icons.view_in_ar_outlined : Icons.image_outlined,
            size: 18,
            color: context.appBrand,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCcta) ...[
                Row(
                  children: [
                    Text(
                      'CCTA AI 연동 영상',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.appSurfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'CCTA',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  '검사 #${cctaResult.examinationId} · '
                  'Analysis #${cctaResult.analysisId} · '
                  'Result #${cctaResult.id}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Text(
                      '${study.modality} Study #${study.id}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    if (study.isDemo) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'UI DEMO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  '검사 #${study.examinationId} · '
                  'Series ${study.seriesCount} · '
                  'Instance ${study.instanceCount}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (isCcta)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _activeCctaResult = null;
              });
            },
            icon: const Icon(Icons.list_alt_outlined, size: 15),
            label: const Text('일반 영상 보기', style: TextStyle(fontSize: 10.5)),
          )
        else if (_comparisonCandidate != null)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _compareMode = true;
              });
            },
            icon: const Icon(Icons.compare_outlined, size: 15),
            label: const Text('이전 영상 비교', style: TextStyle(fontSize: 10.5)),
          ),
      ],
    );
  }

  // ============================================================
  // STEP 10. Compare
  // ============================================================

  Widget _buildCompareView() {
    final comparison = _comparisonCandidate;

    if (comparison == null) {
      _compareMode = false;

      return _buildViewerWorkspace();
    }

    return ImagingCompareView(
      currentStudy: _selectedStudy,

      comparisonStudy: comparison,

      onClose: () {
        setState(() {
          _compareMode = false;
        });
      },
    );
  }

  // ============================================================
  // STEP 11. Message
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
