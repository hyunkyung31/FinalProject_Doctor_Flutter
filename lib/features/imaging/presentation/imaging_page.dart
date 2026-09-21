import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_context.dart';
import '../../../core/widgets/app_shell.dart';

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
  const ImagingPage({super.key});

  @override
  State<ImagingPage> createState() => _ImagingPageState();
}

class _ImagingPageState extends State<ImagingPage> {
  late final List<ImagingStudyUiModel> _studies;
  late final List<ImagingSeriesUiModel> _series;

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

  // ============================================================
  // STEP 2. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _studies = _buildStudies();
    _series = _buildSeries();

    _selectedStudyId = 1007;
    _selectedSeriesId = 1036;
  }

  // ============================================================
  // STEP 3. Selected Data
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
    final matchingSeries = _series
        .where((item) => item.imagingStudyId == study.id)
        .toList();

    setState(() {
      _selectedStudyId = study.id;

      _selectedSeriesId = matchingSeries.isEmpty
          ? null
          : matchingSeries.first.id;

      _currentIndex = 0;

      _viewerMode = ImagingViewerMode.slice2d;

      _isPlaying = false;
      _zoom = 1.0;
      _panEnabled = false;

      _segmentationEnabled = false;
      _cacEnabled = false;
      _bboxEnabled = false;
      _heatmapEnabled = false;
    });
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
          child: _compareMode ? _buildCompareView() : _buildViewerWorkspace(),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 9. Normal Viewer Workspace
  // ============================================================

  Widget _buildViewerWorkspace() {
    final study = _selectedStudy;
    final series = _selectedSeries;

    return Column(
      children: [
        // ======================================================
        // Top Summary
        // ======================================================
        Row(
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
                Icons.image_outlined,
                size: 18,
                color: context.appBrand,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    '검사 #${study.examinationId} · Series ${study.seriesCount} · Instance ${study.instanceCount}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            if (_comparisonCandidate != null)
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
        ),

        const SizedBox(height: 10),

        // ======================================================
        // Main Workspace
        // ======================================================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // Study
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
              // Viewer
              // ==================================================
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

              // ==================================================
              // Info
              // ==================================================
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
          ),
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

  // ============================================================
  // STEP 12. Study Mock
  //
  // #1007 / #538 = 확인된 실제 API 구조 기반
  // #2001 = XA Viewer UI 검증용 Mock
  // ============================================================

  List<ImagingStudyUiModel> _buildStudies() {
    return [
      ImagingStudyUiModel(
        id: 1007,
        examinationId: 712,
        studyInstanceUid: '2.25.90187278800491954439506446217243859775',
        orthancStudyId: '18292436-7ce0207f-50283b94-4dc9b419-fd33fe98',
        modality: 'CT',
        studyDate: null,
        status: 'RECEIVED',
        createdAt: DateTime(2026, 8, 31, 5, 4),
        errorCode: null,
        errorMessage: null,
        validatedAt: null,
        seriesCount: 1,
        instanceCount: 1,
      ),

      ImagingStudyUiModel(
        id: 538,
        examinationId: 712,
        studyInstanceUid:
            '6.08692310586987459129.36970459.09916796023655743015474417098053',
        orthancStudyId: 'fe951d6b-e50304ae-2bca0def-db051722-82e5255d',
        modality: 'CT',
        studyDate: null,
        status: 'RECEIVED',
        createdAt: DateTime(2026, 8, 31, 4, 13),
        errorCode: null,
        errorMessage: null,
        validatedAt: null,
        seriesCount: 1,
        instanceCount: 44,
      ),

      ImagingStudyUiModel(
        id: 1006,
        examinationId: 537,
        studyInstanceUid:
            '4.06120820908957266409.79524322.24111091124940893367800663712640',
        orthancStudyId: '1667dad0-0e6ecebc-c10a2b49-9803401d-ebcd18c9',
        modality: 'CT',
        studyDate: null,
        status: 'RECEIVED',
        createdAt: DateTime(2026, 8, 31, 4, 41),
        errorCode: null,
        errorMessage: null,
        validatedAt: null,
        seriesCount: 1,
        instanceCount: 57,
      ),

      // ========================================================
      // 실제 XA Study 응답 확인 전 Viewer UI 검증용
      // ========================================================
      ImagingStudyUiModel(
        id: 2001,
        examinationId: 9001,
        studyInstanceUid: 'DEMO-XA-STUDY-2001',
        orthancStudyId: 'DEMO-XA-ORTHANC',
        modality: 'XA',
        studyDate: DateTime(2026, 9, 11),
        status: 'RECEIVED',
        createdAt: DateTime(2026, 9, 11, 10, 30),
        errorCode: null,
        errorMessage: null,
        validatedAt: null,
        seriesCount: 1,
        instanceCount: 126,
        isDemo: true,
      ),
    ];
  }

  // ============================================================
  // STEP 13. Series Mock
  // ============================================================

  List<ImagingSeriesUiModel> _buildSeries() {
    return [
      ImagingSeriesUiModel(
        id: 1036,
        imagingStudyId: 1007,
        seriesInstanceUid: '2.25.286335094279215617218295945887653641595',
        orthancSeriesId: '287c758c-79675e3c-6108618f-4d2b68ac-3e4ae478',
        seriesNumber: null,
        modality: 'CT',
        bodySite: null,
        description: 'CCTA Series',
        instanceCount: 1,
      ),

      ImagingSeriesUiModel(
        id: 5381,
        imagingStudyId: 538,
        seriesInstanceUid: 'COMPARE-SERIES-538',
        orthancSeriesId: 'COMPARE-ORTHANC-538',
        seriesNumber: 1,
        modality: 'CT',
        bodySite: 'CHEST',
        description: '이전 CCTA',
        instanceCount: 44,
      ),

      ImagingSeriesUiModel(
        id: 10061,
        imagingStudyId: 1006,
        seriesInstanceUid: 'CT-SERIES-1006',
        orthancSeriesId: 'CT-ORTHANC-1006',
        seriesNumber: 1,
        modality: 'CT',
        bodySite: 'CHEST',
        description: 'CCTA CT Series',
        instanceCount: 57,
      ),

      ImagingSeriesUiModel(
        id: 20011,
        imagingStudyId: 2001,
        seriesInstanceUid: 'DEMO-XA-SERIES',
        orthancSeriesId: 'DEMO-XA-SERIES-ORTHANC',
        seriesNumber: 1,
        modality: 'XA',
        bodySite: 'HEART',
        description: '2D 관상동맥 혈관조영술',
        instanceCount: 126,
      ),
    ];
  }
}
