import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../ai/data/services/ai_analysis_service.dart';
import '../../ai/presentation/ai_ui_models.dart';
import '../../ai/presentation/report/ai_medical_report.dart';
import '../data/services/imaging_service.dart';
import 'widgets/ccta_anatomy_3d_viewer.dart';

// ============================================================
// STEP 1. CCTA Viewer - Final Layout
// ============================================================

class CctaViewerPage extends StatefulWidget {
  final AiResultUiModel result;
  final bool embedded;

  const CctaViewerPage({
    super.key,
    required this.result,
    this.embedded = false,
  });

  @override
  State<CctaViewerPage> createState() => _CctaViewerPageState();
}

enum _ViewerMode { ct, threeD }

// ============================================================
// STEP. CT / 3D Annotation Tool
//
// XCA Viewer와 같은 Annotation 도구를 CT와 3D에 공통 적용한다.
// - CT: Slice(Instance) 단위로 저장
// - 3D Anatomy: anatomy.glb 화면 단위로 저장
// - Patient STL: 환자 석회화 3D 화면 단위로 저장
// 좌표는 모두 0~1 정규화 화면 좌표를 사용한다.
// ============================================================

enum _CctaAnnotationTool { pointer, freehand, rectangle, text }

enum _CctaAnnotationType { freehand, rectangle, text }

class _CctaViewerPageState extends State<CctaViewerPage> {
  AiAnalysisService? _aiService;
  _CctaService? _service;
  ImagingService? _imagingService;

  AiAnalysisPatientContextRecord? _patient;
  _Study? _study;
  List<_Series> _series = [];
  _Series? _selectedSeries;
  List<_Instance> _instances = [];
  List<Map<String, dynamic>> _renderings = [];

  int _index = 0;

  final Map<int, Uint8List> _previewCache = {};
  final TransformationController _ctTransform = TransformationController();

  // ==========================================================
  // CT / 3D Annotation State
  // ==========================================================

  _CctaAnnotationTool _annotationTool = _CctaAnnotationTool.pointer;
  Color _annotationColor = Colors.redAccent;

  // CT는 Instance별로 따로 보관한다.
  final Map<int, List<_CctaAnnotation>> _instanceAnnotations = {};

  // 3D는 해부학 GLB / 환자 STL을 서로 분리해서 보관한다.
  final List<_CctaAnnotation> _anatomy3DAnnotations = <_CctaAnnotation>[];

  _CctaAnnotation? _activeAnnotation;
  String? _selectedAnnotationId;

  Uint8List? _previewBytes;
  int? _patientMeshFileId;

  _ViewerMode _mode = _ViewerMode.ct;

  bool _loading = true;
  bool _seriesLoading = false;
  bool _previewLoading = false;

  String? _pageError;
  String? _dicomMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_service != null) {
      return;
    }

    final api = context.read<AuthProvider>().authService.apiClient;

    _aiService = AiAnalysisService(apiClient: api);
    _service = _CctaService(apiClient: api);
    _imagingService = ImagingService(apiClient: api);

    _load();
  }

  @override
  void dispose() {
    _ctTransform.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 2. Initial Data
  // ============================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _pageError = null;
    });

    try {
      final patient = await _aiService!.fetchPatientContext(
        widget.result.examinationId,
      );

      if (!mounted) {
        return;
      }

      final detail = await _aiService!.fetchAnalysisDetail(
        widget.result.analysisId,
      );

      if (!mounted) {
        return;
      }

      int? studyId;

      for (final input in detail.inputs) {
        final current = input.imagingStudyId;

        if (current != null && current > 0) {
          studyId = current;
          break;
        }
      }

      _Study? study;

      if (studyId != null) {
        try {
          study = await _service!.study(studyId);
        } catch (_) {
          study = _Study(
            id: studyId,
            description: 'CCTA Study #$studyId',
            modality: 'CT',
          );
        }
      } else {
        final studies = await _service!.studies(
          patientId: patient.patientId,
          examinationId: widget.result.examinationId,
        );

        if (studies.isNotEmpty) {
          study = studies.first;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _patient = patient;
        _study = study;
      });

      if (study != null) {
        try {
          final renderings = await _imagingService!.fetchRenderings(study.id);

          if (mounted) {
            setState(() {
              _renderings = renderings;
            });
          }
        } catch (error) {
          debugPrint('[CCTA RENDERINGS ERROR] $error');
        }

        await _loadSeries(study.id);
      } else {
        setState(() {
          _dicomMessage = 'AI Analysis 또는 검사에 연결된 ImagingStudy를 찾지 못했습니다.';
        });
      }

      await _loadFirstPatientMesh();

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _pageError = error.toString();
      });
    }
  }

  // ============================================================
  // STEP 3. CT Study / Series / Instance
  // ============================================================

  Future<void> _loadSeries(int studyId) async {
    setState(() {
      _seriesLoading = true;
      _dicomMessage = null;
    });

    try {
      final values = await _service!.series(studyId);

      if (!mounted) {
        return;
      }

      setState(() {
        _series = values;
        _selectedSeries = values.isEmpty ? null : values.first;
        _seriesLoading = false;
      });

      if (_selectedSeries == null) {
        setState(() {
          _dicomMessage = '이 Study에 등록된 DICOM Series가 없습니다.';
        });
        return;
      }

      await _loadInstances(_selectedSeries!.id);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _seriesLoading = false;
        _dicomMessage = error.toString();
      });
    }
  }

  Future<void> _selectSeries(_Series value) async {
    if (_selectedSeries?.id == value.id) {
      return;
    }

    _resetCtView();

    setState(() {
      _selectedSeries = value;
      _instances = [];
      _index = 0;
      _previewBytes = null;
      _dicomMessage = null;
    });

    await _loadInstances(value.id);
  }

  Future<void> _loadInstances(int seriesId) async {
    setState(() {
      _seriesLoading = true;
      _previewBytes = null;
      _index = 0;
      _dicomMessage = null;
    });

    try {
      final values = await _service!.instances(seriesId);

      if (!mounted) {
        return;
      }

      setState(() {
        _instances = values;
        _seriesLoading = false;
      });

      if (values.isEmpty) {
        setState(() {
          _dicomMessage = '선택한 Series에 DICOM Instance가 없습니다.';
        });
        return;
      }

      await _loadPreview(0);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _seriesLoading = false;
        _dicomMessage = error.toString();
      });
    }
  }

  Future<void> _loadPreview(int next) async {
    if (next < 0 || next >= _instances.length) {
      return;
    }

    final instance = _instances[next];

    setState(() {
      _index = next;
      _previewLoading = true;
      _dicomMessage = null;
      _activeAnnotation = null;
      _selectedAnnotationId = null;
    });

    final cached = _previewCache[instance.id];

    if (cached != null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _previewBytes = cached;
        _previewLoading = false;
      });

      _preload(next + 1);
      return;
    }

    try {
      final bytes = await _service!.instancePreview(instance.id);
      _previewCache[instance.id] = bytes;

      if (!mounted || _index != next) {
        return;
      }

      setState(() {
        _previewBytes = bytes;
        _previewLoading = false;
      });

      _preload(next + 1);
    } catch (error) {
      if (!mounted || _index != next) {
        return;
      }

      setState(() {
        _previewBytes = null;
        _previewLoading = false;
        _dicomMessage = error.toString();
      });
    }
  }

  Future<void> _preload(int next) async {
    if (next < 0 || next >= _instances.length) {
      return;
    }

    final instance = _instances[next];

    if (_previewCache.containsKey(instance.id)) {
      return;
    }

    try {
      _previewCache[instance.id] = await _service!.instancePreview(instance.id);
    } catch (_) {}
  }

  // ============================================================
  // STEP 4. Patient-specific Calcification STL
  // ============================================================

  Future<void> _loadFirstPatientMesh() async {
    int? fileId;

    for (final item in widget.result.segmentationDetails) {
      if (item.meshFileAssetId != null) {
        fileId = item.meshFileAssetId;
        break;
      }
    }

    fileId ??= _toInt(_latestCompletedCalcificationRendering?['file_asset']);

    if (!mounted) {
      return;
    }

    setState(() {
      _patientMeshFileId = fileId;
    });
  }

  Map<String, dynamic>? get _latestCompletedCalcificationRendering {
    Map<String, dynamic>? selected;
    int selectedVersion = -1;

    for (final item in _renderings) {
      final type = item['rendering_type']?.toString().toUpperCase();
      final status = item['status']?.toString().toUpperCase();
      final version = _toInt(item['version']) ?? 0;

      if (type != 'CALCIFICATION_ONLY' || status != 'COMPLETED') {
        continue;
      }

      if (version > selectedVersion) {
        selected = item;
        selectedVersion = version;
      }
    }

    return selected;
  }

  // ============================================================
  // STEP 5. CT / 3D Annotation
  //
  // XCA Viewer와 동일 기능:
  // - 선택 / Viewer 조작
  // - 자유 그리기
  // - 사각형
  // - 텍스트
  // - 색상 선택
  // - 마지막 작업 취소
  // - 선택 삭제
  // - 현재 화면 전체 삭제
  //
  // 3D Annotation은 모델 표면 좌표가 아니라 현재 3D Viewer 화면 위에
  // 겹치는 2D Overlay Annotation이다. 3D 카메라를 돌리면 Annotation은
  // 화면 좌표에 그대로 남는다.
  // ============================================================

  bool get _annotationSurfaceAvailable {
    if (_mode == _ViewerMode.ct) {
      return _previewBytes != null &&
          _instances.isNotEmpty &&
          _index >= 0 &&
          _index < _instances.length;
    }

    return true;
  }

  String get _annotationScopeLabel {
    if (_mode == _ViewerMode.ct) {
      return '현재 Slice';
    }

    return '3D 렌더링';
  }

  List<_CctaAnnotation> get _currentAnnotations {
    if (_mode == _ViewerMode.ct) {
      if (_instances.isEmpty || _index < 0 || _index >= _instances.length) {
        return const <_CctaAnnotation>[];
      }

      final instance = _instances[_index];
      return _instanceAnnotations[instance.id] ?? const <_CctaAnnotation>[];
    }

    return _anatomy3DAnnotations;
  }

  List<_CctaAnnotation>? _mutableCurrentAnnotations({bool create = false}) {
    if (_mode == _ViewerMode.ct) {
      if (_instances.isEmpty || _index < 0 || _index >= _instances.length) {
        return null;
      }

      final instanceId = _instances[_index].id;

      if (create) {
        return _instanceAnnotations.putIfAbsent(
          instanceId,
          () => <_CctaAnnotation>[],
        );
      }

      return _instanceAnnotations[instanceId];
    }

    return _anatomy3DAnnotations;
  }

  void _cleanupCurrentAnnotationList() {
    if (_mode != _ViewerMode.ct ||
        _instances.isEmpty ||
        _index < 0 ||
        _index >= _instances.length) {
      return;
    }

    final instanceId = _instances[_index].id;
    final annotations = _instanceAnnotations[instanceId];

    if (annotations != null && annotations.isEmpty) {
      _instanceAnnotations.remove(instanceId);
    }
  }

  String get _annotationToolLabel {
    switch (_annotationTool) {
      case _CctaAnnotationTool.pointer:
        return '선택 / 조작';
      case _CctaAnnotationTool.freehand:
        return '자유 그리기';
      case _CctaAnnotationTool.rectangle:
        return '사각형';
      case _CctaAnnotationTool.text:
        return '텍스트';
    }
  }

  bool get _annotationNavigationMode {
    return _annotationTool == _CctaAnnotationTool.pointer;
  }

  void _setAnnotationTool(_CctaAnnotationTool tool) {
    setState(() {
      _annotationTool = tool;
      _activeAnnotation = null;

      if (tool != _CctaAnnotationTool.pointer) {
        _selectedAnnotationId = null;
      }
    });
  }

  void _resetAnnotationSelection() {
    _activeAnnotation = null;
    _selectedAnnotationId = null;
  }

  Offset _normalizeAnnotationPoint(Offset point, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return Offset.zero;
    }

    return Offset(
      (point.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (point.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  String _newAnnotationId() {
    final scope = _mode == _ViewerMode.ct
        ? (_instances.isEmpty ? 'ct' : 'ct-${_instances[_index].id}')
        : 'ccta-3d';

    return '$scope-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _startAnnotationGesture(DragStartDetails details, Size size) {
    if (!_annotationSurfaceAvailable ||
        _annotationTool == _CctaAnnotationTool.pointer ||
        _annotationTool == _CctaAnnotationTool.text) {
      return;
    }

    final point = _normalizeAnnotationPoint(details.localPosition, size);
    late final _CctaAnnotation annotation;

    switch (_annotationTool) {
      case _CctaAnnotationTool.freehand:
        annotation = _CctaAnnotation.freehand(
          id: _newAnnotationId(),
          color: _annotationColor,
          points: <Offset>[point],
        );
        break;

      case _CctaAnnotationTool.rectangle:
        annotation = _CctaAnnotation.rectangle(
          id: _newAnnotationId(),
          color: _annotationColor,
          start: point,
          end: point,
        );
        break;

      case _CctaAnnotationTool.pointer:
      case _CctaAnnotationTool.text:
        return;
    }

    final annotations = _mutableCurrentAnnotations(create: true);

    if (annotations == null) {
      return;
    }

    setState(() {
      annotations.add(annotation);
      _activeAnnotation = annotation;
      _selectedAnnotationId = annotation.id;
    });
  }

  void _updateAnnotationGesture(DragUpdateDetails details, Size size) {
    final annotation = _activeAnnotation;

    if (annotation == null) {
      return;
    }

    final point = _normalizeAnnotationPoint(details.localPosition, size);

    setState(() {
      switch (annotation.type) {
        case _CctaAnnotationType.freehand:
          annotation.points.add(point);
          break;

        case _CctaAnnotationType.rectangle:
          annotation.end = point;
          break;

        case _CctaAnnotationType.text:
          break;
      }
    });
  }

  void _endAnnotationGesture() {
    final annotation = _activeAnnotation;

    if (annotation == null) {
      return;
    }

    if (annotation.type == _CctaAnnotationType.rectangle) {
      final start = annotation.start;
      final end = annotation.end;

      if (start != null && end != null) {
        final width = (end.dx - start.dx).abs();
        final height = (end.dy - start.dy).abs();

        if (width < 0.008 || height < 0.008) {
          final annotations = _mutableCurrentAnnotations();

          setState(() {
            annotations?.removeWhere((item) => item.id == annotation.id);
            _cleanupCurrentAnnotationList();
            _selectedAnnotationId = null;
          });
        }
      }
    }

    _activeAnnotation = null;
  }

  Future<void> _addTextAnnotation(Offset localPosition, Size size) async {
    if (!_annotationSurfaceAvailable ||
        _annotationTool != _CctaAnnotationTool.text) {
      return;
    }

    final position = _normalizeAnnotationPoint(localPosition, size);

    final text = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CctaTextAnnotationDialog(),
    );

    if (!mounted || text == null || text.trim().isEmpty) {
      return;
    }

    final annotation = _CctaAnnotation.text(
      id: _newAnnotationId(),
      color: _annotationColor,
      position: position,
      text: text.trim(),
    );

    final annotations = _mutableCurrentAnnotations(create: true);

    if (annotations == null) {
      return;
    }

    setState(() {
      annotations.add(annotation);
      _selectedAnnotationId = annotation.id;
    });
  }

  void _selectAnnotationAtPosition(Offset localPosition, Size size) {
    if (_annotationTool != _CctaAnnotationTool.pointer) {
      return;
    }

    final point = _normalizeAnnotationPoint(localPosition, size);
    String? selectedId;

    for (final annotation in _currentAnnotations.reversed) {
      if (_annotationHitTest(annotation, point, size)) {
        selectedId = annotation.id;
        break;
      }
    }

    setState(() {
      _selectedAnnotationId = selectedId;
    });
  }

  bool _annotationHitTest(_CctaAnnotation annotation, Offset point, Size size) {
    final minSide = math.max(1.0, math.min(size.width, size.height));
    final threshold = 12 / minSide;

    switch (annotation.type) {
      case _CctaAnnotationType.freehand:
        for (final candidate in annotation.points) {
          if ((candidate - point).distance <= threshold) {
            return true;
          }
        }
        return false;

      case _CctaAnnotationType.rectangle:
        final start = annotation.start;
        final end = annotation.end;

        if (start == null || end == null) {
          return false;
        }

        final left = math.min(start.dx, end.dx) - threshold;
        final top = math.min(start.dy, end.dy) - threshold;
        final right = math.max(start.dx, end.dx) + threshold;
        final bottom = math.max(start.dy, end.dy) + threshold;

        return point.dx >= left &&
            point.dx <= right &&
            point.dy >= top &&
            point.dy <= bottom;

      case _CctaAnnotationType.text:
        final position = annotation.position;

        if (position == null) {
          return false;
        }

        final textLength = annotation.text?.length ?? 1;
        final widthPx = math.max(56.0, textLength * 7.5);
        const heightPx = 28.0;
        final width = widthPx / math.max(1.0, size.width);
        final height = heightPx / math.max(1.0, size.height);

        return point.dx >= position.dx - threshold &&
            point.dx <= position.dx + width + threshold &&
            point.dy >= position.dy - threshold &&
            point.dy <= position.dy + height + threshold;
    }
  }

  void _undoAnnotation() {
    final annotations = _mutableCurrentAnnotations();

    if (annotations == null || annotations.isEmpty) {
      return;
    }

    setState(() {
      final removed = annotations.removeLast();

      if (_selectedAnnotationId == removed.id) {
        _selectedAnnotationId = null;
      }

      _cleanupCurrentAnnotationList();
      _activeAnnotation = null;
    });
  }

  void _deleteSelectedAnnotation() {
    final selectedId = _selectedAnnotationId;

    if (selectedId == null) {
      return;
    }

    final annotations = _mutableCurrentAnnotations();

    if (annotations == null) {
      return;
    }

    setState(() {
      annotations.removeWhere((annotation) => annotation.id == selectedId);
      _cleanupCurrentAnnotationList();
      _selectedAnnotationId = null;
      _activeAnnotation = null;
    });
  }

  Future<void> _clearAnnotations() async {
    final annotations = _mutableCurrentAnnotations();

    if (annotations == null || annotations.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Annotation 전체 삭제'),
          content: Text('$_annotationScopeLabel에 작성한 모든 Annotation을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('전체 삭제'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      annotations.clear();
      _cleanupCurrentAnnotationList();
      _activeAnnotation = null;
      _selectedAnnotationId = null;
    });
  }

  // ============================================================
  // STEP. Shared Annotation Overlay
  //
  // CT에서는 InteractiveViewer 내부에 사용하고,
  // 3D에서는 Model/STL Viewer의 stage 위에 2D Overlay로 사용한다.
  // pointer 모드의 3D Overlay는 IgnorePointer로 터치를 통과시켜
  // Drag 회전 / Pinch 확대를 유지한다.
  // ============================================================

  Widget _buildAnnotationOverlay({
    required Size stageSize,
    required bool allowPointerSelection,
  }) {
    final painter = CustomPaint(
      painter: _CctaAnnotationPainter(
        annotations: _currentAnnotations,
        selectedAnnotationId: _selectedAnnotationId,
      ),
      child: const SizedBox.expand(),
    );

    if (_annotationTool == _CctaAnnotationTool.pointer) {
      if (!allowPointerSelection) {
        return IgnorePointer(child: painter);
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          _selectAnnotationAtPosition(details.localPosition, stageSize);
        },
        child: painter,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _annotationTool == _CctaAnnotationTool.text
          ? (details) {
              unawaited(_addTextAnnotation(details.localPosition, stageSize));
            }
          : null,
      onPanStart:
          _annotationTool == _CctaAnnotationTool.freehand ||
              _annotationTool == _CctaAnnotationTool.rectangle
          ? (details) => _startAnnotationGesture(details, stageSize)
          : null,
      onPanUpdate:
          _annotationTool == _CctaAnnotationTool.freehand ||
              _annotationTool == _CctaAnnotationTool.rectangle
          ? (details) => _updateAnnotationGesture(details, stageSize)
          : null,
      onPanEnd:
          _annotationTool == _CctaAnnotationTool.freehand ||
              _annotationTool == _CctaAnnotationTool.rectangle
          ? (_) => _endAnnotationGesture()
          : null,
      onPanCancel:
          _annotationTool == _CctaAnnotationTool.freehand ||
              _annotationTool == _CctaAnnotationTool.rectangle
          ? _endAnnotationGesture
          : null,
      child: painter,
    );
  }

  // ============================================================
  // STEP 6. Viewer Controls
  // ============================================================

  void _resetCtView() {
    _ctTransform.value = Matrix4.identity();
  }

  void _zoomCt(double factor) {
    final currentScale = _ctTransform.value.getMaxScaleOnAxis();
    final target = (currentScale * factor).clamp(0.5, 6.0).toDouble();

    if (currentScale <= 0) {
      return;
    }

    final actual = target / currentScale;
    final next = _ctTransform.value.clone();
    next.scaleByDouble(actual, actual, 1.0, 1.0);
    _ctTransform.value = next;
  }

  Future<void> _refreshCurrentView() async {
    if (_mode == _ViewerMode.ct) {
      final series = _selectedSeries;

      if (series != null) {
        await _loadInstances(series.id);
      }

      return;
    }

    // 3D 렌더링은 asset GLB를 사용하므로 별도 API 새로고침이 필요하지 않는다.
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiMedicalReportPage(result: widget.result),
      ),
    );
  }

  // ============================================================
  // STEP 6. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: context.appBackground,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildWorkspace(),
    );

    if (widget.embedded) {
      return Material(color: context.appBackground, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CCTA Viewer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '검사 #${widget.result.examinationId} · '
              'Analysis #${widget.result.analysisId} · '
              'Result #${widget.result.id}',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
      body: content,
    );
  }

  Widget _buildWorkspace() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildViewerPanel()),
              const SizedBox(width: 12),
              SizedBox(width: 276, child: _buildInfoPanel()),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 7. Compact Header
  // ============================================================

  Widget _buildHeader() {
    final patientName = _patient?.name ?? widget.result.patientName;
    final patientId = _patient?.patientId;

    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined, size: 20, color: context.appBrand),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '관상동맥 CT · 석회화 Review',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$patientName${patientId == null ? '' : ' · #$patientId'}'
                  ' · Examination #${widget.result.examinationId}'
                  ' · Analysis #${widget.result.analysisId}'
                  '${_study == null ? '' : ' · Study #${_study!.id}'}',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 8.8,
                  ),
                ),
              ],
            ),
          ),
          _HeaderChip(label: '${_series.length} Series'),
          const SizedBox(width: 6),
          _HeaderChip(label: '${widget.result.segmentationDetails.length} Seg'),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '현재 보기 새로고침',
            onPressed: _refreshCurrentView,
            icon: const Icon(Icons.refresh_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: _openReport,
            icon: const Icon(Icons.description_outlined, size: 15),
            label: const Text(
              '결과보고서',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 8. Main Viewer
  // ============================================================

  Widget _buildViewerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF08131F),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildViewerModeBar(),
          Expanded(
            child: switch (_mode) {
              _ViewerMode.ct => _buildCtViewer(),
              _ViewerMode.threeD => _buildThreeDViewer(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewerModeBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A28),
        border: Border(bottom: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Row(
        children: [
          const Text(
            'CCTA Viewer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          _DarkModeButton(
            label: '원본 CT',
            icon: Icons.layers_outlined,
            selected: _mode == _ViewerMode.ct,
            onTap: () {
              setState(() {
                _mode = _ViewerMode.ct;
                _resetAnnotationSelection();
              });
            },
          ),
          const SizedBox(width: 6),
          _DarkModeButton(
            label: '3D 렌더링',
            icon: Icons.view_in_ar_outlined,
            selected: _mode == _ViewerMode.threeD,
            onTap: () {
              setState(() {
                _mode = _ViewerMode.threeD;
                _resetAnnotationSelection();
              });
            },
          ),
          const Spacer(),
          Text(
            _mode == _ViewerMode.ct
                ? (_instances.isEmpty
                      ? 'Slice - / -'
                      : 'Slice ${_index + 1} / ${_instances.length}')
                : 'GLB · 혈관 · 석회화',
            style: const TextStyle(color: Colors.white54, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 9. CT Viewer
  // ============================================================

  Widget _buildCtViewer() {
    return Column(
      children: [
        _buildSeriesToolbar(),
        _buildAnnotationToolbar(),
        Expanded(child: _buildCtStage()),
        _buildCtControls(),
      ],
    );
  }

  Widget _buildSeriesToolbar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111F2E),
        border: Border(bottom: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Row(
        children: [
          const Text(
            'Series',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: _buildSeriesDropdown()),
          const SizedBox(width: 10),
          if (_selectedSeries != null)
            Text(
              '${_instances.length} slices',
              style: const TextStyle(color: Colors.white38, fontSize: 8.2),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnotationToolbar() {
    final hasAnnotations = _currentAnnotations.isNotEmpty;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A28),
        border: Border(bottom: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Row(
        children: [
          const Text(
            'Annotation',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 8.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          _buildAnnotationToolButton(
            tool: _CctaAnnotationTool.pointer,
            icon: Icons.near_me_outlined,
            tooltip: _mode == _ViewerMode.threeD
                ? '3D 조작 / Annotation 선택 유지'
                : '선택 / 이동',
          ),
          _buildAnnotationToolButton(
            tool: _CctaAnnotationTool.freehand,
            icon: Icons.draw_outlined,
            tooltip: '자유 그리기',
          ),
          _buildAnnotationToolButton(
            tool: _CctaAnnotationTool.rectangle,
            icon: Icons.crop_square_rounded,
            tooltip: '사각형',
          ),
          _buildAnnotationToolButton(
            tool: _CctaAnnotationTool.text,
            icon: Icons.text_fields_rounded,
            tooltip: '텍스트',
          ),
          _buildAnnotationColorPicker(),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: Colors.white12),
          const SizedBox(width: 6),
          _buildAnnotationEditButton(
            icon: Icons.undo_rounded,
            tooltip: '마지막 작업 취소',
            onPressed: hasAnnotations ? _undoAnnotation : null,
          ),
          _buildAnnotationEditButton(
            icon: Icons.delete_outline_rounded,
            tooltip: '선택 Annotation 삭제',
            foregroundColor: Colors.redAccent,
            selected: _selectedAnnotationId != null,
            onPressed: _selectedAnnotationId == null
                ? null
                : _deleteSelectedAnnotation,
          ),
          _buildAnnotationListButton(),
          PopupMenuButton<String>(
            tooltip: '더보기',
            padding: EdgeInsets.zero,
            color: const Color(0xFF182A3E),
            onSelected: (value) {
              if (value == 'clear_all' && hasAnnotations) {
                unawaited(_clearAnnotations());
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'clear_all',
                  enabled: hasAnnotations,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep_outlined,
                        size: 17,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '$_annotationScopeLabel 전체 삭제',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.more_horiz_rounded,
                size: 17,
                color: Colors.white70,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$_annotationScopeLabel · $_annotationToolLabel · ${_currentAnnotations.length}개',
            style: const TextStyle(color: Colors.white38, fontSize: 7.8),
          ),
        ],
      ),
    );
  }

  String _annotationItemLabel(_CctaAnnotation annotation, int index) {
    final type = switch (annotation.type) {
      _CctaAnnotationType.freehand => '자유그리기',
      _CctaAnnotationType.rectangle => '사각형',
      _CctaAnnotationType.text => '텍스트',
    };

    final text = annotation.text?.trim();
    return text == null || text.isEmpty
        ? '${index + 1}. $type'
        : '${index + 1}. $type · $text';
  }

  Widget _buildAnnotationListButton() {
    final annotations = _currentAnnotations;

    if (annotations.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'Annotation 선택',
      padding: EdgeInsets.zero,
      color: const Color(0xFF182A3E),
      onSelected: (id) {
        setState(() {
          _selectedAnnotationId = id;
        });
      },
      itemBuilder: (context) {
        return [
          for (var index = 0; index < annotations.length; index++)
            PopupMenuItem<String>(
              value: annotations[index].id,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: annotations[index].color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _annotationItemLabel(annotations[index], index),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5),
                    ),
                  ),
                  if (_selectedAnnotationId == annotations[index].id)
                    const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.lightBlueAccent,
                    ),
                ],
              ),
            ),
        ];
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          Icons.format_list_bulleted_rounded,
          size: 16,
          color: _selectedAnnotationId == null
              ? Colors.white60
              : Colors.lightBlueAccent,
        ),
      ),
    );
  }

  Widget _buildAnnotationToolButton({
    required _CctaAnnotationTool tool,
    required IconData icon,
    required String tooltip,
  }) {
    final selected = _annotationTool == tool;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () => _setAnnotationTool(tool),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF2C5F96)
              : Colors.transparent,
          foregroundColor: selected ? Colors.white : Colors.white60,
          minimumSize: const Size(32, 32),
          maximumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildAnnotationEditButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? foregroundColor,
    bool selected = false,
  }) {
    final activeColor = foregroundColor ?? Colors.white;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? activeColor.withValues(alpha: 0.14)
              : Colors.transparent,
          foregroundColor: onPressed == null ? Colors.white24 : activeColor,
          disabledForegroundColor: Colors.white24,
          minimumSize: const Size(32, 32),
          maximumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildAnnotationColorPicker() {
    const colors = <Color>[
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.lightGreenAccent,
      Colors.cyanAccent,
      Colors.lightBlueAccent,
      Colors.purpleAccent,
      Colors.white,
    ];

    return PopupMenuButton<Color>(
      tooltip: 'Annotation 색상',
      onSelected: (color) {
        setState(() {
          _annotationColor = color;
        });
      },
      itemBuilder: (context) {
        return colors.map((color) {
          return PopupMenuItem<Color>(
            value: color,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 9),
                const Text('색상 선택'),
              ],
            ),
          );
        }).toList();
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: _annotationColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesDropdown() {
    if (_seriesLoading && _series.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_series.isEmpty) {
      return const Text(
        'Series 없음',
        style: TextStyle(color: Colors.white38, fontSize: 9),
      );
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedSeries?.id,
          dropdownColor: const Color(0xFF182A3E),
          iconEnabledColor: Colors.white60,
          style: const TextStyle(color: Colors.white, fontSize: 9),
          items: [
            for (final item in _series)
              DropdownMenuItem<int>(
                value: item.id,
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
          ],
          onChanged: _seriesLoading
              ? null
              : (id) {
                  if (id == null) {
                    return;
                  }

                  for (final item in _series) {
                    if (item.id == id) {
                      _selectSeries(item);
                      return;
                    }
                  }
                },
        ),
      ),
    );
  }

  Widget _buildCtStage() {
    final current = _instances.isEmpty ? null : _instances[_index];
    final navigationMode = _annotationTool == _CctaAnnotationTool.pointer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (_previewBytes != null)
              InteractiveViewer(
                transformationController: _ctTransform,
                minScale: 0.5,
                maxScale: 6,
                panEnabled: navigationMode,
                scaleEnabled: navigationMode,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Image.memory(
                          _previewBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),

                      // ==================================================
                      // XCA와 동일한 Medical Annotation Layer
                      // ==================================================
                      Positioned.fill(
                        child: _buildAnnotationOverlay(
                          stageSize: stageSize,
                          allowPointerSelection: true,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: _DarkMessage(
                  icon: Icons.image_outlined,
                  title: _previewLoading || _seriesLoading
                      ? 'CT 원본 연결 중...'
                      : 'CT 미리보기를 표시할 수 없습니다.',
                  message:
                      _dicomMessage ??
                      'Study / Series / Instance 연결 상태를 확인해주세요.',
                ),
              ),
            if (_previewLoading)
              const Positioned(
                right: 14,
                top: 14,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (current != null)
              Positioned(
                left: 12,
                top: 12,
                child: _DarkBadge(
                  label: '${current.label} · Instance #${current.id}',
                ),
              ),
            if (_study != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: _DarkBadge(label: 'Study #${_study!.id}'),
              ),
            if (_previewBytes != null && !navigationMode)
              Positioned(
                left: 12,
                bottom: 12,
                child: _DarkBadge(
                  label: '$_annotationToolLabel 모드 · Pan/Zoom 잠금',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCtControls() {
    final count = _instances.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A28),
        border: Border(top: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 Slice',
                onPressed: count == 0 || _index <= 0
                    ? null
                    : () => _loadPreview(_index - 1),
                color: Colors.white70,
                disabledColor: Colors.white24,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF8DB9E8),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFF8DB9E8),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    min: 0,
                    max: math.max(0, count - 1).toDouble(),
                    divisions: count > 1 ? count - 1 : null,
                    value: count == 0 ? 0 : _index.toDouble(),
                    onChanged: count < 2
                        ? null
                        : (value) {
                            final next = value.round();
                            if (next != _index) {
                              _loadPreview(next);
                            }
                          },
                  ),
                ),
              ),
              SizedBox(
                width: 66,
                child: Text(
                  count == 0 ? '0 / 0' : '${_index + 1} / $count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '다음 Slice',
                onPressed: count == 0 || _index >= count - 1
                    ? null
                    : () => _loadPreview(_index + 1),
                color: Colors.white70,
                disabledColor: Colors.white24,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _ViewerControlButton(
                label: '축소',
                icon: Icons.remove_rounded,
                onPressed: () => _zoomCt(0.82),
              ),
              const SizedBox(width: 5),
              _ViewerControlButton(
                label: '확대',
                icon: Icons.add_rounded,
                onPressed: () => _zoomCt(1.22),
              ),
              const SizedBox(width: 5),
              _ViewerControlButton(
                label: 'Fit / Reset',
                icon: Icons.fit_screen_rounded,
                onPressed: _resetCtView,
              ),
              const Spacer(),
              const Text(
                'Drag 이동 · Pinch 확대/축소',
                style: TextStyle(color: Colors.white38, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 10. 3D Viewer
  // ============================================================

  Widget _buildThreeDViewer() {
    return Column(
      children: [
        _buildAnnotationToolbar(),
        Expanded(
          child: CctaAnatomy3DViewer(
            interactionEnabled: _annotationNavigationMode,
            stageOverlayBuilder: (stageSize) {
              return _buildAnnotationOverlay(
                stageSize: stageSize,
                allowPointerSelection: false,
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 11. Right Info Panel
  // ============================================================

  Widget _buildInfoPanel() {
    final cac = widget.result.cacScore;
    final segmentation = widget.result.segmentationDetails;
    final latestRendering = _latestCompletedCalcificationRendering;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          _InfoSectionTitle('검사 정보'),
          const SizedBox(height: 7),
          _InfoRow(
            label: '환자',
            value: _patient?.name ?? widget.result.patientName,
          ),
          _InfoRow(
            label: 'Patient ID',
            value: _patient == null ? '-' : '#${_patient!.patientId}',
          ),
          _InfoRow(
            label: 'Study',
            value: _study == null ? '-' : '#${_study!.id}',
          ),
          _InfoRow(label: 'Analysis', value: '#${widget.result.analysisId}'),
          _InfoRow(label: 'Model', value: widget.result.modelLabel),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 10),
          _InfoSectionTitle('현재 Viewer'),
          const SizedBox(height: 7),
          _InfoRow(
            label: 'Mode',
            value: _mode == _ViewerMode.ct ? '원본 CT' : '3D 렌더링',
          ),
          if (_mode == _ViewerMode.ct) ...[
            _InfoRow(
              label: 'Series',
              value: _selectedSeries == null
                  ? '-'
                  : (_selectedSeries!.number?.toString() ??
                        '#${_selectedSeries!.id}'),
            ),
            _InfoRow(
              label: 'Slice',
              value: _instances.isEmpty
                  ? '-'
                  : '${_index + 1} / ${_instances.length}',
            ),
            _InfoRow(
              label: 'Annotation',
              value: '${_currentAnnotations.length}개',
            ),
            _InfoRow(label: '도구', value: _annotationToolLabel),
          ] else ...[
            _InfoRow(label: '3D Rendering', value: '혈관 · 석회화'),
            _InfoRow(
              label: 'Annotation',
              value: '${_currentAnnotations.length}개',
            ),
            _InfoRow(label: '도구', value: _annotationToolLabel),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 10),
          _InfoSectionTitle('3D 렌더링 데이터'),
          const SizedBox(height: 7),
          _InfoRow(label: 'GLB', value: 'anatomy.glb'),
          _InfoRow(
            label: '구성',
            value: 'heart · aorta · coronary · calcification',
          ),
          _InfoRow(
            label: '환자 STL',
            value: _patientMeshFileId == null ? '없음' : '#$_patientMeshFileId',
          ),
          _InfoRow(
            label: 'Backend Type',
            value: latestRendering?['rendering_type']?.toString() ?? '-',
          ),
          _InfoRow(
            label: 'Rendering Ver.',
            value: latestRendering?['version']?.toString() ?? '-',
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 10),
          _InfoSectionTitle('AI 석회화'),
          const SizedBox(height: 7),
          _InfoRow(
            label: 'Segmentation',
            value: segmentation.isEmpty ? '없음' : '${segmentation.length}개',
          ),
          for (final item in segmentation) _buildSegmentationInfo(item),
          if (cac != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: context.appBorder),
            const SizedBox(height: 10),
            _InfoSectionTitle('CAC Score'),
            const SizedBox(height: 7),
            _InfoRow(label: 'LAD', value: cac.lad.toStringAsFixed(0)),
            _InfoRow(label: 'LCX', value: cac.lcx.toStringAsFixed(0)),
            _InfoRow(label: 'RCA', value: cac.rca.toStringAsFixed(0)),
            _InfoRow(
              label: 'Total',
              value: cac.total.toStringAsFixed(0),
              emphasized: true,
            ),
          ],
          if (widget.result.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: context.appBorder),
            const SizedBox(height: 10),
            _InfoSectionTitle('AI Summary'),
            const SizedBox(height: 7),
            Text(
              widget.result.summary,
              style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 8.5,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'anatomy.glb는 React와 동일한 해부학 참조/데모 모델입니다. '
              '환자별 실제 AI 석회화 결과는 CALCIFICATION_ONLY STL로 별도 표시합니다. '
              '두 모델을 동일 환자의 정합된 3D로 해석하면 안 됩니다.',
              style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 8.1,
                height: 1.45,
              ),
            ),
          ),
          if (_pageError != null) ...[
            const SizedBox(height: 10),
            Text(
              _pageError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 8.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentationInfo(AiResultSegmentationUiModel item) {
    final rawVoxels = item.metricsJson['raw_voxels'];
    final hu130Voxels = item.metricsJson['hu130_voxels'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.structureName == 'CALCIFICATION'
                ? '석회화 영역'
                : item.structureName,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (rawVoxels != null) _SmallInfoText('전체 voxel · $rawVoxels'),
          if (hu130Voxels != null)
            _SmallInfoText('HU ≥ 130 · $hu130Voxels voxel'),
          if (item.volumeMm3 != null)
            _SmallInfoText(
              'Volume · ${item.volumeMm3!.toStringAsFixed(1)} mm³',
            ),
          if (item.meshFileAssetId != null)
            _SmallInfoText('Mesh File · #${item.meshFileAssetId}'),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 12. CCTA API Service
// ============================================================

class _CctaService {
  final dynamic apiClient;

  const _CctaService({required this.apiClient});

  Future<List<_Study>> studies({
    required int patientId,
    required int examinationId,
  }) async {
    final response = await apiClient.dio.get(
      '/imaging-studies/',
      queryParameters: {
        'patient_id': patientId,
        'examination_id': examinationId,
      },
    );

    return _list(response.data).map(_Study.fromJson).toList();
  }

  Future<_Study> study(int id) async {
    final response = await apiClient.dio.get('/imaging-studies/$id/');
    return _Study.fromJson(_single(response.data));
  }

  Future<List<_Series>> series(int studyId) async {
    final response = await apiClient.dio.get(
      '/imaging-studies/$studyId/series/',
    );

    final values = _list(response.data).map(_Series.fromJson).toList();

    values.sort((a, b) => (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30));

    return values;
  }

  Future<List<_Instance>> instances(int seriesId) async {
    final response = await apiClient.dio.get(
      '/imaging-series/$seriesId/instances/',
    );

    final values = _list(response.data).map(_Instance.fromJson).toList();

    values.sort((a, b) => (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30));

    return values;
  }

  Future<Uint8List> instancePreview(int instanceId) async {
    try {
      final response = await apiClient.dio.get<List<int>>(
        '/imaging-instances/$instanceId/rendered/',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;

      if (data == null || data.isEmpty) {
        throw const _CctaException('DICOM 미리보기 응답이 비어 있습니다.');
      }

      return Uint8List.fromList(data);
    } on DioException catch (error) {
      throw _CctaException(
        _errorText(error, 'DICOM Instance #$instanceId 미리보기를 불러오지 못했습니다.'),
      );
    }
  }

  Future<Uint8List> fileBytes(int fileId) async {
    try {
      final response = await apiClient.dio.get<List<int>>(
        '/files/$fileId/content/',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;

      if (data == null || data.isEmpty) {
        throw const _CctaException('다운로드된 FileAsset이 비어 있습니다.');
      }

      return Uint8List.fromList(data);
    } on DioException catch (error) {
      throw _CctaException(
        _errorText(error, 'FileAsset #$fileId를 불러오지 못했습니다.'),
      );
    }
  }
}

class _CctaException implements Exception {
  final String message;

  const _CctaException(this.message);

  @override
  String toString() => message;
}

// ============================================================
// STEP 13. Internal Models
// ============================================================

class _Study {
  final int id;
  final String description;
  final String modality;

  const _Study({
    required this.id,
    required this.description,
    required this.modality,
  });

  factory _Study.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id'] ?? json['study_id']);

    if (id == null) {
      throw const FormatException('Study ID가 없습니다.');
    }

    return _Study(
      id: id,
      description:
          (json['description'] ?? json['study_description'] ?? 'CCTA Study')
              .toString(),
      modality: (json['modality'] ?? 'CT').toString(),
    );
  }
}

class _Series {
  final int id;
  final int? number;
  final String description;
  final int count;

  const _Series({
    required this.id,
    required this.number,
    required this.description,
    required this.count,
  });

  factory _Series.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id'] ?? json['series_id']);

    if (id == null) {
      throw const FormatException('Series ID가 없습니다.');
    }

    return _Series(
      id: id,
      number: _toInt(json['series_number'] ?? json['seriesNumber']),
      description:
          (json['description'] ?? json['series_description'] ?? 'Series #$id')
              .toString(),
      count:
          _toInt(
            json['instance_count'] ?? json['instanceCount'] ?? json['count'],
          ) ??
          0,
    );
  }

  String get label {
    final prefix = number == null ? 'Series #$id' : 'Series $number';
    final suffix = count > 0 ? ' · $count slices' : '';
    return '$prefix · $description$suffix';
  }
}

class _Instance {
  final int id;
  final int? number;

  const _Instance({required this.id, required this.number});

  factory _Instance.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id'] ?? json['instance_id']);

    if (id == null) {
      throw const FormatException('Instance ID가 없습니다.');
    }

    return _Instance(
      id: id,
      number: _toInt(json['instance_number'] ?? json['instanceNumber']),
    );
  }

  String get label => number == null ? 'Instance #$id' : 'Slice $number';
}

// ============================================================
// STEP 14. UI Helpers
// ============================================================

class _DarkModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DarkModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 9),
            ),
            icon: Icon(icon, size: 14),
            label: Text(label, style: const TextStyle(fontSize: 8.8)),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              disabledForegroundColor: Colors.white24,
              side: const BorderSide(color: Colors.white12),
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 9),
            ),
            icon: Icon(icon, size: 14),
            label: Text(label, style: const TextStyle(fontSize: 8.8)),
          );
  }
}

class _ViewerControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ViewerControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white12),
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 8.2)),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;

  const _HeaderChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appTextSecondary,
          fontSize: 8.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  final String label;

  const _DarkBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DarkMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DarkMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.white30),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionTitle extends StatelessWidget {
  final String title;

  const _InfoSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: context.appTextPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(color: context.appTextSecondary, fontSize: 8.2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 8.4,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoText extends StatelessWidget {
  final String value;

  const _SmallInfoText(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        value,
        style: TextStyle(
          color: context.appTextSecondary,
          fontSize: 7.8,
          height: 1.35,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 15. Text Annotation Dialog
// ============================================================

class _CctaTextAnnotationDialog extends StatefulWidget {
  const _CctaTextAnnotationDialog();

  @override
  State<_CctaTextAnnotationDialog> createState() =>
      _CctaTextAnnotationDialogState();
}

class _CctaTextAnnotationDialogState extends State<_CctaTextAnnotationDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('텍스트 Annotation'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        maxLength: 80,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'CT 영상에 표시할 메모를 입력하세요.'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }
}

// ============================================================
// STEP 16. Annotation Model
// ============================================================

class _CctaAnnotation {
  final String id;
  final _CctaAnnotationType type;
  final Color color;

  final List<Offset> points;

  final Offset? start;
  Offset? end;

  final Offset? position;
  final String? text;

  _CctaAnnotation._({
    required this.id,
    required this.type,
    required this.color,
    this.points = const <Offset>[],
    this.start,
    this.end,
    this.position,
    this.text,
  });

  factory _CctaAnnotation.freehand({
    required String id,
    required Color color,
    required List<Offset> points,
  }) {
    return _CctaAnnotation._(
      id: id,
      type: _CctaAnnotationType.freehand,
      color: color,
      points: points,
    );
  }

  factory _CctaAnnotation.rectangle({
    required String id,
    required Color color,
    required Offset start,
    required Offset end,
  }) {
    return _CctaAnnotation._(
      id: id,
      type: _CctaAnnotationType.rectangle,
      color: color,
      start: start,
      end: end,
    );
  }

  factory _CctaAnnotation.text({
    required String id,
    required Color color,
    required Offset position,
    required String text,
  }) {
    return _CctaAnnotation._(
      id: id,
      type: _CctaAnnotationType.text,
      color: color,
      position: position,
      text: text,
    );
  }
}

// ============================================================
// STEP 17. Medical Annotation Painter
// ============================================================

class _CctaAnnotationPainter extends CustomPainter {
  final List<_CctaAnnotation> annotations;
  final String? selectedAnnotationId;

  const _CctaAnnotationPainter({
    required this.annotations,
    required this.selectedAnnotationId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final selected = annotation.id == selectedAnnotationId;

      switch (annotation.type) {
        case _CctaAnnotationType.freehand:
          _paintFreehand(canvas, size, annotation, selected);
          break;

        case _CctaAnnotationType.rectangle:
          _paintRectangle(canvas, size, annotation, selected);
          break;

        case _CctaAnnotationType.text:
          _paintText(canvas, size, annotation, selected);
          break;
      }
    }
  }

  void _paintFreehand(
    Canvas canvas,
    Size size,
    _CctaAnnotation annotation,
    bool selected,
  ) {
    final points = annotation.points;

    if (points.isEmpty) {
      return;
    }

    final screenPoints = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();

    if (selected) {
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawPolyline(canvas, screenPoints, haloPaint);
    }

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _drawPolyline(canvas, screenPoints, paint);
  }

  void _paintRectangle(
    Canvas canvas,
    Size size,
    _CctaAnnotation annotation,
    bool selected,
  ) {
    final start = annotation.start;
    final end = annotation.end;

    if (start == null || end == null) {
      return;
    }

    final rect = Rect.fromPoints(
      Offset(start.dx * size.width, start.dy * size.height),
      Offset(end.dx * size.width, end.dy * size.height),
    );

    if (selected) {
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, haloPaint);
    }

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    final handlePaint = Paint()
      ..color = annotation.color
      ..style = PaintingStyle.fill;

    const handleRadius = 3.5;

    for (final point in <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(point, handleRadius, handlePaint);
    }
  }

  void _paintText(
    Canvas canvas,
    Size size,
    _CctaAnnotation annotation,
    bool selected,
  ) {
    final position = annotation.position;
    final text = annotation.text;

    if (position == null || text == null || text.isEmpty) {
      return;
    }

    final offset = Offset(position.dx * size.width, position.dy * size.height);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: annotation.color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(80.0, size.width - offset.dx - 8));

    if (selected) {
      final backgroundRect = Rect.fromLTWH(
        offset.dx - 4,
        offset.dy - 3,
        painter.width + 8,
        painter.height + 6,
      );

      final backgroundPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
        backgroundPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
        borderPaint,
      );
    }

    painter.paint(canvas, offset);
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      final dotPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        points.first,
        math.max(1.5, paint.strokeWidth / 2),
        dotPaint,
      );

      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CctaAnnotationPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// STEP 18. Parsing Helpers
// ============================================================

List<Map<String, dynamic>> _list(dynamic data) {
  dynamic raw = data;

  if (data is Map) {
    for (final key in ['results', 'items', 'series', 'instances', 'data']) {
      if (data[key] is List) {
        raw = data[key];
        break;
      }
    }
  }

  return raw is List
      ? raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}

Map<String, dynamic> _single(dynamic data) {
  if (data is Map) {
    for (final key in ['result', 'study', 'file', 'data']) {
      if (data[key] is Map) {
        return Map<String, dynamic>.from(data[key]);
      }
    }

    return Map<String, dynamic>.from(data);
  }

  throw const FormatException('API 응답 형식이 올바르지 않습니다.');
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

String _errorText(DioException error, String fallback) {
  dynamic data = error.response?.data;

  if (data is List<int>) {
    try {
      data = jsonDecode(utf8.decode(data));
    } catch (_) {
      data = null;
    }
  }

  if (data is Map && data['detail'] != null) {
    return data['detail'].toString();
  }

  return fallback;
}
