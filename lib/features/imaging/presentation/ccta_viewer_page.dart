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
import 'widgets/anatomy_model_view.dart';

// ============================================================
// STEP 1. CCTA 전용 Viewer
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

enum _ViewerMode { dicom, mesh, ai }

class _CctaViewerPageState extends State<CctaViewerPage> {
  AiAnalysisService? _aiService;
  _CctaService? _service;
  ImagingService? _imagingService;

  AiAnalysisPatientContextRecord? _patient;
  _Study? _study;
  List<_Series> _series = [];
  _Series? _selectedSeries;
  List<_Instance> _instances = [];
  int _index = 0;

  final Map<int, Uint8List> _previewCache = {};
  Uint8List? _previewBytes;
  Uint8List? _meshBytes;
  int? _meshFileId;

  _ViewerMode _mode = _ViewerMode.dicom;
  bool _loading = true;
  bool _seriesLoading = false;
  bool _previewLoading = false;
  bool _meshLoading = false;
  String? _pageError;
  String? _dicomMessage;
  String? _meshMessage;
  String _anatomyViewMode = 'VESSEL_CALCIFICATION';

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

  // ==========================================================
  // STEP 2. 초기 데이터
  // ==========================================================

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
      _patient = patient;

      final detail = await _aiService!.fetchAnalysisDetail(
        widget.result.analysisId,
      );
      if (!mounted) {
        return;
      }

      int? studyId;
      for (final input in detail.inputs) {
        if (input.imagingStudyId != null && input.imagingStudyId! > 0) {
          studyId = input.imagingStudyId;
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
      setState(() => _study = study);

      if (study != null) {
        final renderings = await _imagingService!.fetchRenderings(study.id);

        debugPrint(
          '[CCTA 3D] studyId=${study.id}, renderings=$renderings',
          wrapWidth: 2048,
        );

        await _loadSeries(study.id);
      } else {
        setState(() {
          _dicomMessage =
              'AI Analysis 또는 검사에 연결된 ImagingStudy를 찾지 못했습니다. 3D Mesh 결과는 별도로 확인할 수 있습니다.';
        });
      }

      await _loadFirstMesh();

      if (mounted) {
        setState(() => _loading = false);
      }
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
        setState(() => _dicomMessage = '이 Study에 등록된 DICOM Series가 없습니다.');
      } else {
        await _loadInstances(_selectedSeries!.id);
      }
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
        setState(() => _dicomMessage = '선택한 Series에 DICOM Instance가 없습니다.');
      } else {
        await _loadPreview(0);
      }
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

  // ==========================================================
  // STEP 3. STL Mesh
  // ==========================================================

  Future<void> _loadFirstMesh() async {
    for (final item in widget.result.segmentationDetails) {
      if (item.meshFileAssetId != null) {
        await _loadMesh(item.meshFileAssetId!);
        return;
      }
    }
    if (mounted) {
      setState(() => _meshMessage = 'Segmentation 결과에 Mesh FileAsset이 없습니다.');
    }
  }

  Future<void> _loadMesh(int fileId) async {
    setState(() {
      _meshFileId = fileId;
      _meshLoading = true;
      _meshMessage = null;
    });
    try {
      final bytes = await _service!.fileBytes(fileId);
      if (!mounted || _meshFileId != fileId) {
        return;
      }
      setState(() {
        _meshBytes = bytes;
        _meshLoading = false;
      });
    } catch (error) {
      if (!mounted || _meshFileId != fileId) {
        return;
      }
      setState(() {
        _meshBytes = null;
        _meshLoading = false;
        _meshMessage = error.toString();
      });
    }
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiMedicalReportPage(result: widget.result),
      ),
    );
  }

  // ==========================================================
  // STEP 4. 화면
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _summaryBar(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _mainViewer()),
                    SizedBox(width: 280, child: _rightPanel()),
                  ],
                ),
              ),
            ],
          );

    // ==========================================================
    // 영상 메뉴 내부에 포함될 때
    // ==========================================================

    if (widget.embedded) {
      return Material(color: context.appBackground, child: content);
    }

    // ==========================================================
    // 기존 독립 실행 방식
    // ==========================================================

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3D CCTA Viewer',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _openReport,
              icon: const Icon(Icons.description_outlined, size: 17),
              label: const Text('결과보고서 작성'),
            ),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _summaryBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border(bottom: BorderSide(color: context.appBorder)),
    ),
    child: Row(
      children: [
        _Chip(
          _patient == null
              ? '환자 확인 중'
              : '${_patient!.name} · #${_patient!.patientId}',
        ),
        const SizedBox(width: 7),
        const _Chip('CCTA'),
        const SizedBox(width: 7),
        _Chip(widget.result.status),
        const SizedBox(width: 7),
        _Chip(_study == null ? 'Study 미연결' : 'Study #${_study!.id}'),
        const Spacer(),

        Text(
          widget.result.modelLabel,
          style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
        ),

        if (widget.embedded) ...[
          const SizedBox(width: 10),

          FilledButton.icon(
            onPressed: _openReport,
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('결과보고서 작성', style: TextStyle(fontSize: 10)),
          ),
        ],
      ],
    ),
  );

  Widget _mainViewer() => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(bottom: BorderSide(color: context.appBorder)),
        ),
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _Mode(
              '원본 CT',
              Icons.layers_outlined,
              _mode == _ViewerMode.dicom,
              () => setState(() => _mode = _ViewerMode.dicom),
            ),
            _Mode(
              anatomyWebViewerAvailable ? '3D 렌더링' : '3D 석회화',
              Icons.view_in_ar_outlined,
              _mode == _ViewerMode.mesh,
              () => setState(() => _mode = _ViewerMode.mesh),
            ),
            _Mode(
              'AI 결과',
              Icons.auto_graph_outlined,
              _mode == _ViewerMode.ai,
              () => setState(() => _mode = _ViewerMode.ai),
            ),
          ],
        ),
      ),
      Expanded(
        child: switch (_mode) {
          _ViewerMode.dicom => _dicomViewer(),
          _ViewerMode.mesh => _meshViewer(),
          _ViewerMode.ai => _aiViewer(),
        },
      ),
    ],
  );

  // ==========================================================
  // STEP 5. 원본 CT
  // ==========================================================

  Widget _dicomViewer() {
    final current = _instances.isEmpty ? null : _instances[_index];
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Text(
                  'Series',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedSeries?.id,
                      hint: const Text('Series 없음'),
                      items: [
                        for (final item in _series)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
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
                                  break;
                                }
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_previewBytes != null)
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 6,
                    child: Center(
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  )
                else
                  Center(
                    child: _Message(
                      Icons.image_outlined,
                      _previewLoading || _seriesLoading
                          ? 'DICOM 원본 연결 중...'
                          : 'DICOM 미리보기를 표시할 수 없습니다.',
                      _dicomMessage ??
                          'Study / Series / Instance 연결 상태를 확인해주세요.',
                    ),
                  ),
                if (_previewLoading)
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (current != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .68),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${current.label} · Instance #${current.id}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _dicomControls(),
        ],
      ),
    );
  }

  Widget _dicomControls() {
    final count = _instances.length;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: count == 0 || _index <= 0
                ? null
                : () => _loadPreview(_index - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
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
          SizedBox(
            width: 70,
            child: Text(
              count == 0 ? '0 / 0' : '${_index + 1} / $count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: count == 0 || _index >= count - 1
                ? null
                : () => _loadPreview(_index + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STEP 6. 3D anatomy (web) / STL fallback
  // 웹 clinician MedicalModelViewer와 같은 GLB를 표시한다.
  // ==========================================================

  Widget _anatomyViewer() {
    const modes = <(String, String)>[
      ('VESSEL', '혈관'),
      ('CALCIFICATION', '석회화'),
      ('VESSEL_CALCIFICATION', '혈관 + 석회화'),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.view_in_ar_outlined,
                size: 17,
                color: context.appTextPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CCTA 3D 렌더링',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '심장 · 대동맥 · 관상동맥 · 석회화',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final mode in modes)
                ChoiceChip(
                  label: Text(mode.$2, style: const TextStyle(fontSize: 11)),
                  selected: _anatomyViewMode == mode.$1,
                  onSelected: (_) =>
                      setState(() => _anatomyViewMode = mode.$1),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnatomyModelView(
            sourceUrl: 'test/anatomy.glb',
            format: 'GLB',
            viewMode: _anatomyViewMode,
          ),
        ),
      ],
    );
  }

  Widget _meshViewer() {
    if (anatomyWebViewerAvailable) {
      return _anatomyViewer();
    }

    final candidates = widget.result.segmentationDetails
        .where((e) => e.meshFileAssetId != null)
        .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.view_in_ar_outlined,
                size: 17,
                color: context.appTextPrimary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '석회화 3D 분할 모델',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '이 실행 파일에는 WebGL이 없어 석회화 STL만 표시됩니다. '
                      '심장 모형은 Chrome으로 연 Flutter web에서 웹과 같이 나옵니다.',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (candidates.length > 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final item in candidates)
                  ChoiceChip(
                    label: Text(
                      item.structureName == 'CALCIFICATION'
                          ? '석회화 영역'
                          : item.structureName,
                      style: const TextStyle(fontSize: 9.5),
                    ),
                    selected: _meshFileId == item.meshFileAssetId,
                    onSelected: (_) => _loadMesh(item.meshFileAssetId!),
                  ),
              ],
            ),
          ),

        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: _meshLoading
                ? const Center(child: CircularProgressIndicator())
                : _meshBytes == null
                ? Center(
                    child: _Message(
                      Icons.view_in_ar_outlined,
                      '3D 모델을 표시할 수 없습니다.',
                      _meshMessage ?? '석회화 분할 결과의 3D 모델을 확인해주세요.',
                    ),
                  )
                : _StlView(bytes: _meshBytes!),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // STEP 7. AI 결과
  // ==========================================================

  Widget _aiViewer() {
    final items = widget.result.segmentationDetails;
    final cac = widget.result.cacScore;

    num? metricNumber(dynamic value) {
      if (value is num) {
        return value;
      }

      return num.tryParse(value?.toString() ?? '');
    }

    final totalHu130Voxels = items.fold<num>(
      0,
      (sum, item) =>
          sum + (metricNumber(item.metricsJson['hu130_voxels']) ?? 0),
    );

    final hasSegmentation = items.isNotEmpty;
    final hasCalcificationSignal = totalHu130Voxels > 0;
    final hasMesh = items.any((item) => item.meshFileAssetId != null);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'AI 분석 결과',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          widget.result.summary.trim().isEmpty
              ? 'CCTA 영상 기반 석회화 분석 결과입니다.'
              : widget.result.summary,
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: context.appTextSecondary,
          ),
        ),

        const SizedBox(height: 16),

        // ========================================================
        // 분석 상태
        // ========================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            children: [
              _KV('분석 상태', hasSegmentation ? '분할 완료' : '분할 결과 없음', bold: true),
              _KV('석회화 영역', hasCalcificationSignal ? '확인됨' : '확인되지 않음'),
              _KV('3D 모델', hasMesh ? '생성 완료' : '생성되지 않음'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // 분할 결과
        // ========================================================
        Text(
          '석회화 분할 정보',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),

        const SizedBox(height: 8),

        if (!hasSegmentation)
          const _Message(
            Icons.hub_outlined,
            '분할 결과가 없습니다.',
            '현재 AI 결과에 연결된 Segmentation 데이터가 없습니다.',
          )
        else
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border.all(color: context.appBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.structureName == 'CALCIFICATION'
                        ? '석회화 영역'
                        : item.structureName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 9),

                  if (item.metricsJson['raw_voxels'] != null)
                    _KV('전체 검출 voxel', '${item.metricsJson['raw_voxels']}'),

                  if (item.metricsJson['hu130_voxels'] != null)
                    _KV(
                      'HU ≥ 130 voxel',
                      '${item.metricsJson['hu130_voxels']}',
                    ),

                  if (item.volumeMm3 != null)
                    _KV('분할 부피', '${item.volumeMm3!.toStringAsFixed(1)} mm³'),

                  _KV(
                    '3D 시각화',
                    item.meshFileAssetId != null ? '사용 가능' : '사용 불가',
                  ),
                ],
              ),
            ),

        if (hasMesh) ...[
          const SizedBox(height: 2),

          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _mode = _ViewerMode.mesh;
                });
              },
              icon: const Icon(Icons.view_in_ar_outlined, size: 17),
              label: Text(
                anatomyWebViewerAvailable ? '3D 렌더링에서 보기' : '3D 석회화에서 위치 확인',
              ),
            ),
          ),
        ],

        // ========================================================
        // CAC Score - 실제 값이 있을 때만 노출
        // ========================================================
        if (cac != null) ...[
          const SizedBox(height: 18),

          Text(
            '관상동맥 석회화 점수 (CAC)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border.all(color: context.appBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _KV('LAD', cac.lad.toStringAsFixed(0)),
                _KV('LCX', cac.lcx.toStringAsFixed(0)),
                _KV('RCA', cac.rca.toStringAsFixed(0)),
                Divider(color: context.appBorder),
                _KV('Total', cac.total.toStringAsFixed(0), bold: true),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: context.appTextSecondary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'AI 기반 CCTA 석회화 분할 결과입니다. '
                  '3D 시각화는 위치 확인을 위한 보조 정보이며, '
                  '최종 판독은 원본 CT와 환자의 임상 정보를 함께 검토해야 합니다.',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightPanel() => Container(
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border(left: BorderSide(color: context.appBorder)),
    ),
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'CCTA 정보',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _KV('Patient', '#${_patient?.patientId ?? '-'}'),
        _KV('Study', '#${_study?.id ?? '-'}'),
        _KV('Series', '${_series.length}개'),
        _KV('현재 Images', '${_instances.length}장'),
        _KV('Segmentation', '${widget.result.segmentationDetails.length}개'),
        const SizedBox(height: 12),
        Divider(color: context.appBorder),
        const SizedBox(height: 8),
        Text(
          'AI 분할 결과',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in widget.result.segmentationDetails)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.structureName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meshFileAssetId != null ? '분할 완료 · 3D 모델 생성됨' : '분할 완료',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (_pageError != null)
          Text(
            _pageError!,
            style: TextStyle(
              fontSize: 9.5,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    ),
  );
}

// ============================================================
// STEP 8. CCTA API Service
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

  // ============================================================
  // STEP. Study 3D Rendering 목록 확인
  // ============================================================
  Future<List<Map<String, dynamic>>> renderings(int studyId) async {
    final response = await apiClient.dio.get(
      '/staff/imaging-studies/$studyId/renderings-3d/',
    );
    final data = response.data;
    debugPrint(
      '[CCTA RENDERINGS] studyId=$studyId, data=$data',
      wrapWidth: 2048,
    );
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

      final head = data == null
          ? ''
          : data
                .take(16)
                .map((value) => value.toRadixString(16).padLeft(2, '0'))
                .join(' ');

      debugPrint(
        '[CCTA PREVIEW] '
        'instanceId=$instanceId, '
        'status=${response.statusCode}, '
        'contentType=${response.headers.value('content-type')}, '
        'bytes=${data?.length ?? 0}, '
        'head=$head',
        wrapWidth: 1024,
      );

      if (data == null || data.isEmpty) {
        throw const _CctaException('DICOM 미리보기 응답이 비어 있습니다.');
      }

      return Uint8List.fromList(data);
    } on DioException catch (error) {
      debugPrint(
        '[CCTA PREVIEW ERROR] '
        'instanceId=$instanceId, '
        'status=${error.response?.statusCode}, '
        'dataType=${error.response?.data.runtimeType}, '
        'error=$error',
        wrapWidth: 1024,
      );

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

      debugPrint(
        '[CCTA FILE CONTENT] '
        'fileId=$fileId, '
        'status=${response.statusCode}, '
        'contentType=${response.headers.value('content-type')}, '
        'bytes=${data?.length ?? 0}',
        wrapWidth: 1024,
      );

      if (data == null || data.isEmpty) {
        throw const _CctaException('다운로드된 FileAsset이 비어 있습니다.');
      }

      return Uint8List.fromList(data);
    } on DioException catch (error) {
      debugPrint(
        '[CCTA FILE ERROR] '
        'fileId=$fileId, '
        'status=${error.response?.statusCode}, '
        'error=$error',
        wrapWidth: 1024,
      );

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
    final id = _id(json['id'] ?? json['study_id']);
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
    final id = _id(json['id'] ?? json['series_id']);
    if (id == null) {
      throw const FormatException('Series ID가 없습니다.');
    }
    return _Series(
      id: id,
      number: _id(json['series_number'] ?? json['seriesNumber']),
      description:
          (json['description'] ?? json['series_description'] ?? 'Series #$id')
              .toString(),
      count:
          _id(
            json['instance_count'] ?? json['instanceCount'] ?? json['count'],
          ) ??
          0,
    );
  }
  String get label =>
      '${number == null ? 'Series #$id' : 'Series $number'} · $description${count > 0 ? ' ($count)' : ''}';
}

class _Instance {
  final int id;
  final int? number;
  const _Instance({required this.id, required this.number});
  factory _Instance.fromJson(Map<String, dynamic> json) {
    final id = _id(json['id'] ?? json['instance_id']);
    if (id == null) {
      throw const FormatException('Instance ID가 없습니다.');
    }
    return _Instance(
      id: id,
      number: _id(json['instance_number'] ?? json['instanceNumber']),
    );
  }
  String get label => number == null ? 'Instance #$id' : 'Slice $number';
}

// ============================================================
// STEP 9. Pure Flutter STL Viewer
// Drag=회전 / Pinch=확대 / DoubleTap=초기화
// 외부 3D package 없이 binary/ascii STL을 표시한다.
// ============================================================

class _StlView extends StatefulWidget {
  final Uint8List bytes;
  const _StlView({required this.bytes});

  @override
  State<_StlView> createState() => _StlViewState();
}

class _StlViewState extends State<_StlView> {
  late _Mesh _mesh;
  double _yaw = -.55;
  double _pitch = .3;
  double _zoom = 1.35;
  double _startZoom = 1.35;

  @override
  void initState() {
    super.initState();
    _mesh = _Mesh.parse(widget.bytes);
  }

  @override
  void didUpdateWidget(covariant _StlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _mesh = _Mesh.parse(widget.bytes);
      _yaw = -.55;
      _pitch = .3;
      _zoom = 1.35;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mesh.triangles.isEmpty) {
      return const Center(child: Text('3D 모델 데이터를 읽지 못했습니다.'));
    }

    void resetView() {
      setState(() {
        _yaw = -.55;
        _pitch = .3;
        _zoom = 1.35;
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: resetView,
      onScaleStart: (_) {
        _startZoom = _zoom;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount >= 2) {
            _zoom = (_startZoom * details.scale).clamp(.45, 4.0).toDouble();
          } else {
            _yaw += details.focalPointDelta.dx * .01;

            _pitch = (_pitch + details.focalPointDelta.dy * .01)
                .clamp(-1.4, 1.4)
                .toDouble();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MeshPainter(
              mesh: _mesh,
              yaw: _yaw,
              pitch: _pitch,
              zoom: _zoom,
              base: Theme.of(context).colorScheme.primary,
              edge: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: .22),
            ),
          ),

          // ======================================================
          // 석회화 모델 안내
          // ======================================================
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    size: 15,
                    color: context.appTextPrimary,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    '석회화 분할 3D',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // 초기화 버튼
          // ======================================================
          Positioned(
            right: 14,
            top: 14,
            child: IconButton.filledTonal(
              tooltip: '3D 화면 초기화',
              onPressed: resetView,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
            ),
          ),

          // ======================================================
          // 조작 안내
          // ======================================================
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Drag 회전 · Pinch 확대/축소 · 두 번 탭 초기화',
                style: TextStyle(fontSize: 9, color: context.appTextSecondary),
              ),
            ),
          ),

          // ======================================================
          // 임상 오해 방지 안내
          // ======================================================
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '현재 모델은 혈관 전체가 아닌 '
                'AI 분할 석회화 영역을 표시합니다.',
                style: TextStyle(
                  fontSize: 8.5,
                  height: 1.4,
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mesh {
  final List<_Tri> triangles;
  const _Mesh(this.triangles);

  factory _Mesh.parse(Uint8List bytes) {
    const maxTriangles = 12000;
    List<_Tri> raw = [];

    if (bytes.length >= 84) {
      final data = ByteData.sublistView(bytes);
      final count = data.getUint32(80, Endian.little);
      final expected = 84 + count * 50;
      if (count > 0 && expected <= bytes.length) {
        final step = math.max(1, (count / maxTriangles).ceil()).toInt();
        for (var i = 0; i < count; i += step) {
          final o = 84 + i * 50;
          _V v(int x) => _V(
            data.getFloat32(o + x, Endian.little),
            data.getFloat32(o + x + 4, Endian.little),
            data.getFloat32(o + x + 8, Endian.little),
          );
          raw.add(_Tri(v(12), v(24), v(36)));
          if (raw.length >= maxTriangles) {
            break;
          }
        }
      }
    }

    if (raw.isEmpty) {
      final text = utf8.decode(bytes, allowMalformed: true);
      if (text.trimLeft().toLowerCase().startsWith('solid')) {
        final re = RegExp(
          r'vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)',
          caseSensitive: false,
        );
        final vertices = <_V>[];
        for (final m in re.allMatches(text)) {
          final x = double.tryParse(m.group(1) ?? '');
          final y = double.tryParse(m.group(2) ?? '');
          final z = double.tryParse(m.group(3) ?? '');
          if (x != null && y != null && z != null) {
            vertices.add(_V(x, y, z));
          }
        }
        final count = vertices.length ~/ 3;
        final step = math.max(1, (count / maxTriangles).ceil()).toInt();
        for (var i = 0; i < count; i += step) {
          final p = i * 3;
          raw.add(_Tri(vertices[p], vertices[p + 1], vertices[p + 2]));
          if (raw.length >= maxTriangles) {
            break;
          }
        }
      }
    }

    if (raw.isEmpty) {
      return const _Mesh([]);
    }

    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;
    for (final t in raw) {
      for (final v in [t.a, t.b, t.c]) {
        minX = math.min(minX, v.x);
        minY = math.min(minY, v.y);
        minZ = math.min(minZ, v.z);
        maxX = math.max(maxX, v.x);
        maxY = math.max(maxY, v.y);
        maxZ = math.max(maxZ, v.z);
      }
    }
    final cx = (minX + maxX) / 2,
        cy = (minY + maxY) / 2,
        cz = (minZ + maxZ) / 2;
    final extent = math.max(maxX - minX, math.max(maxY - minY, maxZ - minZ));
    final scale = extent.abs() < 1e-9 ? 1.0 : extent;
    _V n(_V v) =>
        _V((v.x - cx) / scale, (v.y - cy) / scale, (v.z - cz) / scale);
    return _Mesh([for (final t in raw) _Tri(n(t.a), n(t.b), n(t.c))]);
  }
}

class _MeshPainter extends CustomPainter {
  final _Mesh mesh;
  final double yaw, pitch, zoom;
  final Color base, edge;
  const _MeshPainter({
    required this.mesh,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.base,
    required this.edge,
  });

  _V rot(_V s) {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x = s.x * cy + s.z * sy;
    final z1 = -s.x * sy + s.z * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    return _V(x, s.y * cp - z1 * sp, s.y * sp + z1 * cp);
  }

  Offset project(_V v, Size size) {
    final scale = math.min(size.width, size.height) * .82 * zoom;
    final perspective = 1 / (1.75 + v.z * .55);
    return Offset(
      size.width / 2 + v.x * scale * perspective,
      size.height / 2 - v.y * scale * perspective,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = <_PaintTri>[];
    for (final t in mesh.triangles) {
      final a = rot(t.a), b = rot(t.b), c = rot(t.c);
      final ab = b - a, ac = c - a;
      var nx = ab.y * ac.z - ab.z * ac.y;
      var ny = ab.z * ac.x - ab.x * ac.z;
      var nz = ab.x * ac.y - ab.y * ac.x;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 1e-9) {
        nx /= len;
        ny /= len;
        nz /= len;
      }
      if (nz > .18) {
        continue;
      }
      final light = (.42 + (-nz * .45) + (-ny * .12))
          .clamp(.18, .96)
          .toDouble();
      rows.add(
        _PaintTri(
          project(a, size),
          project(b, size),
          project(c, size),
          (a.z + b.z + c.z) / 3,
          light,
        ),
      );
    }
    rows.sort((a, b) => a.depth.compareTo(b.depth));
    for (final t in rows) {
      final path = Path()
        ..moveTo(t.a.dx, t.a.dy)
        ..lineTo(t.b.dx, t.b.dy)
        ..lineTo(t.c.dx, t.c.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(Colors.black, base, t.light)!
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = .35,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.mesh != mesh ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom ||
      old.base != base;
}

class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);
  _V operator -(_V o) => _V(x - o.x, y - o.y, z - o.z);
}

class _Tri {
  final _V a, b, c;
  const _Tri(this.a, this.b, this.c);
}

class _PaintTri {
  final Offset a, b, c;
  final double depth, light;
  const _PaintTri(this.a, this.b, this.c, this.depth, this.light);
}

// ============================================================
// STEP 10. UI / Parsing Helpers
// ============================================================

class _Mode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Mode(this.label, this.icon, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => selected
      ? FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 10)),
        )
      : OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 10)),
        );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.appSurfaceSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: context.appTextSecondary,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const _Message(this.icon, this.title, this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 34, color: context.appTextSecondary),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            height: 1.5,
            color: context.appTextSecondary,
          ),
        ),
      ],
    ),
  );
}

class _KV extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _KV(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: context.appTextPrimary,
          ),
        ),
      ],
    ),
  );
}

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
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
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

int? _id(dynamic value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '');

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
