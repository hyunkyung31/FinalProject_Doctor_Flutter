import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme_context.dart';
import '../../../core/widgets/app_shell.dart';

import '../data/models/xca_detail_models.dart';
import '../data/models/xca_report_models.dart';
import '../data/services/xca_detail_service.dart';
import '../data/services/xca_report_service.dart';

import 'xca_pdf_preview_page.dart';

// ============================================================
// STEP 1. ANGIO Viewer Page
// ============================================================

class AngioViewerPage extends StatefulWidget {
  final int examinationId;
  final int patientId;
  final int? analysisId;

  const AngioViewerPage({
    super.key,
    required this.examinationId,
    required this.patientId,
    this.analysisId,
  });

  @override
  State<AngioViewerPage> createState() => _AngioViewerPageState();
}

class _AngioViewerPageState extends State<AngioViewerPage> {
  XcaDetailService? _service;
  XcaReportService? _reportService;

  XcaDetailRecord? _detail;
  XcaSequenceRecord? _selectedSequence;

  List<XcaFrameRecord> _frames = [];

  bool _isDetailLoading = true;
  bool _isFrameLoading = false;
  bool _isPreparingPlayback = false;

  // ============================================================
  // STEP. Annotation State
  //
  // React Viewer의 pointer / freehand / rectangle / text 구조를
  // Flutter ANGIO Viewer에 맞게 Frame 단위 Annotation으로 구현한다.
  // 좌표는 모두 0~1 정규화 좌표로 보관한다.
  // ============================================================

  _AngioAnnotationTool _annotationTool = _AngioAnnotationTool.pointer;
  Color _annotationColor = Colors.redAccent;

  final Map<int, List<_AngioAnnotation>> _frameAnnotations = {};

  _AngioAnnotation? _activeAnnotation;
  String? _selectedAnnotationId;

  // ============================================================
  // STEP. Report Frame Selection State
  //
  // React XCA Viewer와 동일하게 하나의 XCA Detail 안에서
  // Series가 바뀌어도 선택을 유지하며 최대 12개까지 선택한다.
  // Signed URL은 저장하지 않고 Frame/Sequence 식별자만 보관한다.
  // ============================================================

  static const int _maxReportFrameSelection = 12;

  final Map<int, _SelectedReportFrame> _selectedReportFrames =
      <int, _SelectedReportFrame>{};

  bool _isSavingReport = false;
  bool _isLoadingReportPdf = false;

  XcaReportVersionRecord? _lastSavedReportVersion;
  int? _lastSavedMedicalResultId;

  String? _error;

  int _currentIndex = 0;

  bool _isPlaying = false;

  // 실제 촬영 FPS가 아니라 Viewer 재생 배속이다.
  double _playbackSpeed = 1.0;

  bool _showAiPreview = true;
  bool _showBoundingBox = true;

  Timer? _playbackTimer;
  Timer? _signedUrlRefreshTimer;

  int _frameRequestVersion = 0;

  // ============================================================
  // STEP. Cine Playback Cache
  //
  // 원본 source URL만 재생 캐시에 올린다.
  // 동일 URL의 중복 precache 요청은 Future를 공유한다.
  // ============================================================

  final Set<String> _readyPlaybackUrls = <String>{};
  final Map<String, Future<bool>> _playbackCacheTasks =
      <String, Future<bool>>{};

  int _playbackCacheGeneration = 0;

  // ============================================================
  // STEP 2. Lifecycle
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_service != null && _reportService != null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final apiClient = auth.authService.apiClient;

    _service ??= XcaDetailService(apiClient: apiClient);
    _reportService ??= XcaReportService(apiClient: apiClient);

    // Hot Reload로 Report Service만 새로 추가된 경우
    // 기존 XCA Detail을 불필요하게 다시 조회하지 않는다.
    if (_detail == null) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _signedUrlRefreshTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Detail Load
  // ============================================================

  Future<void> _loadDetail() async {
    setState(() {
      _isDetailLoading = true;
      _error = null;
    });

    try {
      final detail = await _service!.fetchDetailForAnalysis(
        examinationId: widget.examinationId,
        patientId: widget.patientId,
        analysisId: widget.analysisId,
      );

      if (!mounted) {
        return;
      }

      if (detail.sequences.isEmpty) {
        setState(() {
          _detail = detail;
          _isDetailLoading = false;
          _error = '연결된 ANGIO Series가 없습니다.';
        });

        return;
      }

      setState(() {
        _detail = detail;
        _selectedSequence = detail.sequences.first;
        _isDetailLoading = false;
      });

      await _loadFrames(detail.sequences.first);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDetailLoading = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // STEP 4. Sequence Frame Load
  // ============================================================

  Future<void> _loadFrames(
    XcaSequenceRecord sequence, {
    bool preserveCurrentFrame = false,
  }) async {
    final detail = _detail;

    if (detail == null) {
      return;
    }

    final requestVersion = ++_frameRequestVersion;

    final previousFrameIndex = _frames.isEmpty
        ? 0
        : _frames[_currentIndex.clamp(0, _frames.length - 1)].frameIndex;

    _stopPlayback();

    // 이전 Series / 이전 Signed URL 캐시 상태는 현재 재생 판단에 사용하지 않는다.
    _playbackCacheGeneration += 1;
    _readyPlaybackUrls.clear();
    _playbackCacheTasks.clear();

    setState(() {
      _selectedSequence = sequence;
      _isFrameLoading = true;
      _error = null;

      if (!preserveCurrentFrame) {
        _currentIndex = 0;
        _frames = [];
      }
    });

    try {
      final frames = await _service!.fetchSequenceFrames(
        detailId: detail.id,
        patientId: widget.patientId,
        sequenceId: sequence.sequenceId,
      );

      if (!mounted || requestVersion != _frameRequestVersion) {
        return;
      }

      int nextIndex = 0;

      if (preserveCurrentFrame && frames.isNotEmpty) {
        final matchedIndex = frames.indexWhere(
          (frame) => frame.frameIndex == previousFrameIndex,
        );

        if (matchedIndex >= 0) {
          nextIndex = matchedIndex;
        }
      } else if (frames.isNotEmpty &&
          sequence.representativeFrameIndex != null) {
        final representativeIndex = frames.indexWhere(
          (frame) => frame.frameIndex == sequence.representativeFrameIndex,
        );

        if (representativeIndex >= 0) {
          nextIndex = representativeIndex;
        }
      }

      setState(() {
        _frames = frames;
        _currentIndex = nextIndex;
        _isFrameLoading = false;
        _selectedAnnotationId = null;
        _activeAnnotation = null;
      });

      _scheduleSignedUrlRefresh();

      // 화면 진입 직후 현재 Frame + 앞쪽 몇 장을 background에서 준비한다.
      // Play 버튼을 누를 때 기다리는 시간을 줄이기 위한 warm-up이다.
      unawaited(_precachePlaybackWindow(startIndex: nextIndex, count: 3));
    } catch (error) {
      if (!mounted || requestVersion != _frameRequestVersion) {
        return;
      }

      setState(() {
        _isFrameLoading = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // STEP 5. Signed URL Refresh
  // expires_in = 300초
  // 4분마다 현재 Sequence URL 갱신
  // ============================================================

  void _scheduleSignedUrlRefresh() {
    _signedUrlRefreshTimer?.cancel();

    _signedUrlRefreshTimer = Timer(const Duration(minutes: 4), () async {
      final sequence = _selectedSequence;

      if (!mounted || sequence == null) {
        return;
      }

      final wasPlaying = _isPlaying;

      await _loadFrames(sequence, preserveCurrentFrame: true);

      if (!mounted || !wasPlaying || _frames.length <= 1) {
        return;
      }

      await _togglePlayback();
    });
  }

  // ============================================================
  // STEP. Cine Play / Pause
  // ============================================================

  Future<void> _togglePlayback() async {
    if (_frames.length <= 1 || _isPreparingPlayback) {
      return;
    }

    if (_isPlaying) {
      _stopPlayback();
      return;
    }

    if (_annotationTool != _AngioAnnotationTool.pointer) {
      setState(() {
        _annotationTool = _AngioAnnotationTool.pointer;
        _activeAnnotation = null;
        _selectedAnnotationId = null;
      });
    }

    setState(() {
      _isPreparingPlayback = true;
    });

    try {
      // 전체 Series를 기다리지 않는다.
      // 현재 Frame + 다음 1장만 확실히 준비한 뒤 Cine을 시작한다.
      await _precachePlaybackWindow(
        startIndex: _currentIndex,
        count: 2,
        waitForCompletion: true,
      );

      if (!mounted) {
        return;
      }

      _startPlayback();

      // 그 뒤 Frame은 재생과 동시에 background에서 준비한다.
      unawaited(
        _precachePlaybackWindow(
          startIndex: (_currentIndex + 2) % _frames.length,
          count: 6,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingPlayback = false;
        });
      }
    }
  }

  // ============================================================
  // STEP. Cine Playback
  //
  // 중요한 원칙:
  // 다음 Frame 이미지가 준비됐을 때만 index 이동
  //
  // → Network가 재생보다 느려도 검은 화면으로 넘어가지 않음
  // ============================================================

  void _startPlayback() {
    _playbackTimer?.cancel();

    setState(() {
      _isPlaying = true;
    });

    // 실제 촬영 FPS가 아니라 Viewer 재생 속도다.
    final milliseconds = math.max(50, (100 / _playbackSpeed).round());

    _playbackTimer = Timer.periodic(Duration(milliseconds: milliseconds), (_) {
      if (!mounted || !_isPlaying || _frames.length <= 1) {
        return;
      }

      final nextIndex = (_currentIndex + 1) % _frames.length;
      final nextFrame = _frames[nextIndex];
      final nextUrl = _playbackFrameUrl(nextFrame);

      // 다음 원본 Frame이 아직 준비되지 않았으면
      // 현재 Frame을 그대로 유지한다.
      // index를 먼저 넘기지 않으므로 검은 화면으로 진행하지 않는다.
      if (!_readyPlaybackUrls.contains(nextUrl)) {
        unawaited(_ensurePlaybackFrameReady(nextUrl));

        unawaited(_precachePlaybackWindow(startIndex: nextIndex, count: 5));

        return;
      }

      setState(() {
        _currentIndex = nextIndex;
        _selectedAnnotationId = null;
        _activeAnnotation = null;
      });

      // 작은 look-ahead window만 유지한다.
      // 매 tick마다 많은 이미지를 동시에 요청하지 않도록 count를 제한한다.
      unawaited(
        _precachePlaybackWindow(
          startIndex: (_currentIndex + 1) % _frames.length,
          count: 5,
        ),
      );
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    if (mounted && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _changePlaybackSpeed(double speed) {
    final wasPlaying = _isPlaying;

    _playbackTimer?.cancel();

    setState(() {
      _playbackSpeed = speed;
      _isPlaying = false;
    });

    if (wasPlaying) {
      _startPlayback();
    }
  }

  // ============================================================
  // STEP 7. Frame Navigation
  // ============================================================

  void _setCurrentIndex(int index, {bool stopPlayback = true}) {
    if (_frames.isEmpty) {
      return;
    }

    if (stopPlayback && _isPlaying) {
      _stopPlayback();
    }

    final safeIndex = index.clamp(0, _frames.length - 1);

    setState(() {
      _currentIndex = safeIndex;
      _selectedAnnotationId = null;
      _activeAnnotation = null;
    });

    unawaited(_precachePlaybackWindow(startIndex: safeIndex, count: 4));
  }

  void _previousFrame() {
    if (_frames.isEmpty) {
      return;
    }

    _setCurrentIndex(
      _currentIndex <= 0 ? _frames.length - 1 : _currentIndex - 1,
    );
  }

  void _nextFrame() {
    if (_frames.isEmpty) {
      return;
    }

    _setCurrentIndex((_currentIndex + 1) % _frames.length);
  }

  // ============================================================
  // STEP. frame_index 값으로 직접 이동
  // ============================================================

  void _jumpToFrameIndexValue(int frameIndex) {
    if (_frames.isEmpty) {
      return;
    }

    final targetIndex = _frames.indexWhere(
      (frame) => frame.frameIndex == frameIndex,
    );

    if (targetIndex < 0) {
      return;
    }

    _setCurrentIndex(targetIndex);
  }

  // ============================================================
  // STEP. Playback Frame Cache
  //
  // precacheImage가 완료된 URL만 ready로 인정한다.
  // 같은 URL이 이미 loading 중이면 그 Future를 그대로 공유한다.
  // ============================================================

  Future<bool> _ensurePlaybackFrameReady(String url) {
    if (!mounted || url.isEmpty) {
      return Future<bool>.value(false);
    }

    if (_readyPlaybackUrls.contains(url)) {
      return Future<bool>.value(true);
    }

    final existingTask = _playbackCacheTasks[url];

    if (existingTask != null) {
      return existingTask;
    }

    final generation = _playbackCacheGeneration;
    final completer = Completer<bool>();
    final task = completer.future;

    _playbackCacheTasks[url] = task;

    () async {
      var ready = false;

      try {
        await precacheImage(NetworkImage(url), context);

        if (mounted && generation == _playbackCacheGeneration) {
          _readyPlaybackUrls.add(url);
          ready = true;
        }
      } catch (error) {
        debugPrint('[ANGIO VIEWER] Playback Frame cache 실패: $error');
      } finally {
        if (identical(_playbackCacheTasks[url], task)) {
          _playbackCacheTasks.remove(url);
        }

        if (!completer.isCompleted) {
          completer.complete(ready);
        }
      }
    }();

    return task;
  }

  // ============================================================
  // 현재 위치 기준으로 원본 Frame 일부만 준비
  // ============================================================

  Future<void> _precachePlaybackWindow({
    required int startIndex,
    int count = 5,
    bool waitForCompletion = false,
  }) async {
    if (!mounted || _frames.isEmpty || count <= 0) {
      return;
    }

    final safeCount = math.min(count, _frames.length);

    final futures = <Future<bool>>[];

    for (var offset = 0; offset < safeCount; offset++) {
      final index = (startIndex + offset) % _frames.length;

      futures.add(_ensurePlaybackFrameReady(_playbackFrameUrl(_frames[index])));
    }

    if (waitForCompletion) {
      await Future.wait(futures);
    }
  }

  // ============================================================
  // STEP 8. Current Frame
  // ============================================================

  XcaFrameRecord? get _currentFrame {
    if (_frames.isEmpty) {
      return null;
    }

    final safeIndex = _currentIndex.clamp(0, _frames.length - 1);

    return _frames[safeIndex];
  }

  // ============================================================
  // STEP. Report Frame Selection
  // ============================================================

  bool get _isCurrentFrameSelectedForReport {
    final frame = _currentFrame;

    if (frame == null) {
      return false;
    }

    return _selectedReportFrames.containsKey(frame.id);
  }

  void _toggleCurrentFrameReportSelection() {
    final frame = _currentFrame;
    final sequence = _selectedSequence;

    if (frame == null || sequence == null) {
      return;
    }

    if (_selectedReportFrames.containsKey(frame.id)) {
      setState(() {
        _selectedReportFrames.remove(frame.id);
      });

      return;
    }

    if (_selectedReportFrames.length >= _maxReportFrameSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보고서에 선택할 수 있는 Frame은 최대 12개입니다.')),
      );

      return;
    }

    setState(() {
      _selectedReportFrames[frame.id] = _SelectedReportFrame(
        frameId: frame.id,
        sequenceId: frame.sequenceId,
        sequenceNo: frame.sequenceNo,
        frameIndex: frame.frameIndex,
        sideLabel: sequence.sideLabel,
      );
    });
  }

  void _removeReportFrame(int frameId) {
    if (!_selectedReportFrames.containsKey(frameId)) {
      return;
    }

    setState(() {
      _selectedReportFrames.remove(frameId);
    });
  }

  Future<void> _clearReportFrameSelection() async {
    if (_selectedReportFrames.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('보고서 선택 Frame 해제'),
          content: Text(
            '선택한 ${_selectedReportFrames.length}개 Frame을 모두 해제할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('전체 해제'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _selectedReportFrames.clear();
    });
  }

  Future<void> _openSelectedReportFrame(_SelectedReportFrame selected) async {
    final detail = _detail;

    if (detail == null) {
      return;
    }

    XcaSequenceRecord? targetSequence;

    for (final sequence in detail.sequences) {
      if (sequence.sequenceId == selected.sequenceId) {
        targetSequence = sequence;
        break;
      }
    }

    if (targetSequence == null) {
      return;
    }

    if (_selectedSequence?.sequenceId != targetSequence.sequenceId) {
      await _loadFrames(targetSequence);

      if (!mounted) {
        return;
      }
    }

    _jumpToFrameIndexValue(selected.frameIndex);
  }

  // ============================================================
  // STEP. XCA 보고서 초안 저장
  //
  // 1) 현재 Examination + AIAnalysisResult로 MedicalResult 확보
  // 2) 최신 ReportVersion 조회
  // 3) 최신 version.id를 base_version_id로 사용
  // 4) 선택 Frame + 의료진 의견을 XCA attachment로 저장
  //
  // Annotation 도형 자체는 현재 Backend 계약에 없으므로 저장하지 않는다.
  // ============================================================

  Future<void> _openReportDraftDialog() async {
    final detail = _detail;

    if (detail == null ||
        _reportService == null ||
        _selectedReportFrames.isEmpty ||
        _isSavingReport) {
      return;
    }

    final selectedFrames = _selectedReportFrames.values.toList(growable: false);

    final reviewNote = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _XcaReportDraftDialog(
          examinationId: widget.examinationId,
          detailId: detail.id,
          aiResultId: detail.resultId,
          selectedFrames: selectedFrames,
        );
      },
    );

    if (!mounted || reviewNote == null) {
      return;
    }

    final trimmedNote = reviewNote.trim();

    if (trimmedNote.isEmpty) {
      return;
    }

    setState(() {
      _isSavingReport = true;
    });

    try {
      final result = await _reportService!.saveXcaDraft(
        examinationId: widget.examinationId,
        patientId: widget.patientId,
        analysisResultId: detail.resultId,
        detailId: detail.id,
        frameIds: selectedFrames
            .map((item) => item.frameId)
            .toList(growable: false),
        reviewNote: trimmedNote,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastSavedReportVersion = result.reportVersion;
        _lastSavedMedicalResultId = result.medicalResultId;

        // 같은 선택을 실수로 연속 저장하는 일을 줄이기 위해
        // 성공 후 현재 선택 목록은 비운다.
        _selectedReportFrames.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.reused
                ? '기존 XCA 보고서 첨부를 확인했습니다. '
                      'v${result.reportVersion.versionNo}'
                : 'XCA 보고서 초안 저장 완료 · '
                      'v${result.reportVersion.versionNo}',
          ),
        ),
      );
    } on XcaReportConflictException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on XcaReportException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('보고서 초안 저장 중 오류가 발생했습니다. $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingReport = false;
        });
      }
    }
  }

  // ============================================================
  // STEP. 저장된 XCA Draft PDF 미리보기
  //
  // GET /api/report-versions/{version_id}/xca-pdf/
  //     ?patient_id={patient_id}
  //
  // JWT가 필요한 PDF이므로 외부 URL을 직접 여는 대신
  // 기존 ApiClient(Dio)로 bytes를 받은 뒤 Flutter 내부에서 렌더링한다.
  // ============================================================

  Future<void> _openSavedReportPdfPreview() async {
    final reportVersion = _lastSavedReportVersion;
    final medicalResultId = _lastSavedMedicalResultId;
    final reportService = _reportService;

    if (reportVersion == null ||
        medicalResultId == null ||
        reportService == null ||
        _isLoadingReportPdf) {
      return;
    }

    setState(() {
      _isLoadingReportPdf = true;
    });

    try {
      final document = await reportService.fetchXcaPdfDocument(
        versionId: reportVersion.id,
        patientId: widget.patientId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return XcaPdfPreviewPage(
              pdfBytes: document.bytes,
              contentSha256: document.contentSha256,
              initiallySigned: document.isSigned,
              versionId: reportVersion.id,
              versionNo: reportVersion.versionNo,
              patientId: widget.patientId,
              medicalResultId: medicalResultId,
            );
          },
        ),
      );
    } on XcaReportException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('XCA Draft PDF를 불러오지 못했습니다. $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReportPdf = false;
        });
      }
    }
  }

  // ============================================================
  // STEP. Annotation
  // ============================================================

  List<_AngioAnnotation> get _currentAnnotations {
    final frame = _currentFrame;

    if (frame == null) {
      return const <_AngioAnnotation>[];
    }

    return _frameAnnotations[frame.id] ?? const <_AngioAnnotation>[];
  }

  String get _annotationToolLabel {
    switch (_annotationTool) {
      case _AngioAnnotationTool.pointer:
        return '선택';
      case _AngioAnnotationTool.freehand:
        return '자유 그리기';
      case _AngioAnnotationTool.rectangle:
        return '사각형';
      case _AngioAnnotationTool.text:
        return '텍스트';
    }
  }

  void _setAnnotationTool(_AngioAnnotationTool tool) {
    if (tool != _AngioAnnotationTool.pointer) {
      _stopPlayback();
    }

    setState(() {
      _annotationTool = tool;
      _activeAnnotation = null;

      if (tool != _AngioAnnotationTool.pointer) {
        _selectedAnnotationId = null;
      }
    });
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

  String _newAnnotationId(int frameId) {
    return '$frameId-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _startAnnotationGesture(DragStartDetails details, Size size) {
    final frame = _currentFrame;

    if (frame == null ||
        _annotationTool == _AngioAnnotationTool.pointer ||
        _annotationTool == _AngioAnnotationTool.text) {
      return;
    }

    _stopPlayback();

    final point = _normalizeAnnotationPoint(details.localPosition, size);

    late final _AngioAnnotation annotation;

    switch (_annotationTool) {
      case _AngioAnnotationTool.freehand:
        annotation = _AngioAnnotation.freehand(
          id: _newAnnotationId(frame.id),
          color: _annotationColor,
          points: <Offset>[point],
        );
        break;

      case _AngioAnnotationTool.rectangle:
        annotation = _AngioAnnotation.rectangle(
          id: _newAnnotationId(frame.id),
          color: _annotationColor,
          start: point,
          end: point,
        );
        break;

      case _AngioAnnotationTool.pointer:
      case _AngioAnnotationTool.text:
        return;
    }

    setState(() {
      final annotations = _frameAnnotations.putIfAbsent(
        frame.id,
        () => <_AngioAnnotation>[],
      );

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
        case _AngioAnnotationType.freehand:
          annotation.points.add(point);
          break;

        case _AngioAnnotationType.rectangle:
          annotation.end = point;
          break;

        case _AngioAnnotationType.text:
          break;
      }
    });
  }

  void _endAnnotationGesture() {
    final frame = _currentFrame;
    final annotation = _activeAnnotation;

    if (frame == null || annotation == null) {
      _activeAnnotation = null;
      return;
    }

    if (annotation.type == _AngioAnnotationType.rectangle) {
      final start = annotation.start;
      final end = annotation.end;

      if (start != null && end != null) {
        final width = (end.dx - start.dx).abs();
        final height = (end.dy - start.dy).abs();

        if (width < 0.008 || height < 0.008) {
          final annotations = _frameAnnotations[frame.id];

          setState(() {
            annotations?.removeWhere((item) => item.id == annotation.id);

            if (annotations != null && annotations.isEmpty) {
              _frameAnnotations.remove(frame.id);
            }

            _selectedAnnotationId = null;
          });
        }
      }
    }

    _activeAnnotation = null;
  }

  Future<void> _addTextAnnotation(Offset localPosition, Size size) async {
    final frame = _currentFrame;

    if (frame == null || _annotationTool != _AngioAnnotationTool.text) {
      return;
    }

    _stopPlayback();

    final position = _normalizeAnnotationPoint(localPosition, size);

    // onTapDown 중에 route를 바로 push하지 않는다.
    // Gesture arena 처리가 끝난 onTapUp에서 호출하고,
    // TextField의 controller/focus 수명은 Dialog State가 직접 관리한다.
    final text = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _TextAnnotationDialog(),
    );

    if (!mounted || text == null || text.trim().isEmpty) {
      return;
    }

    final annotation = _AngioAnnotation.text(
      id: _newAnnotationId(frame.id),
      color: _annotationColor,
      position: position,
      text: text.trim(),
    );

    setState(() {
      final annotations = _frameAnnotations.putIfAbsent(
        frame.id,
        () => <_AngioAnnotation>[],
      );

      annotations.add(annotation);
      _selectedAnnotationId = annotation.id;
    });
  }

  void _selectAnnotationAt(TapDownDetails details, Size size) {
    if (_annotationTool != _AngioAnnotationTool.pointer) {
      return;
    }

    final point = _normalizeAnnotationPoint(details.localPosition, size);

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

  bool _annotationHitTest(
    _AngioAnnotation annotation,
    Offset point,
    Size size,
  ) {
    final minSide = math.max(1.0, math.min(size.width, size.height));

    final threshold = 12 / minSide;

    switch (annotation.type) {
      case _AngioAnnotationType.freehand:
        for (final candidate in annotation.points) {
          if ((candidate - point).distance <= threshold) {
            return true;
          }
        }

        return false;

      case _AngioAnnotationType.rectangle:
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

      case _AngioAnnotationType.text:
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
    final frame = _currentFrame;

    if (frame == null) {
      return;
    }

    final annotations = _frameAnnotations[frame.id];

    if (annotations == null || annotations.isEmpty) {
      return;
    }

    setState(() {
      final removed = annotations.removeLast();

      if (_selectedAnnotationId == removed.id) {
        _selectedAnnotationId = null;
      }

      if (annotations.isEmpty) {
        _frameAnnotations.remove(frame.id);
      }

      _activeAnnotation = null;
    });
  }

  void _deleteSelectedAnnotation() {
    final frame = _currentFrame;
    final selectedId = _selectedAnnotationId;

    if (frame == null || selectedId == null) {
      return;
    }

    final annotations = _frameAnnotations[frame.id];

    if (annotations == null) {
      return;
    }

    setState(() {
      annotations.removeWhere((annotation) => annotation.id == selectedId);

      if (annotations.isEmpty) {
        _frameAnnotations.remove(frame.id);
      }

      _selectedAnnotationId = null;
      _activeAnnotation = null;
    });
  }

  // ============================================================
  // STEP. 현재 Frame Annotation 전체 삭제
  // ============================================================

  Future<void> _clearAnnotations() async {
    final frame = _currentFrame;

    if (frame == null) {
      return;
    }

    final annotations = _frameAnnotations[frame.id];

    if (annotations == null || annotations.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Annotation 전체 삭제'),
          content: const Text('현재 Frame에 작성한 모든 Annotation을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
      _frameAnnotations.remove(frame.id);

      _selectedAnnotationId = null;
      _activeAnnotation = null;
    });
  }

  // ============================================================
  // STEP. Playback / Display URL
  //
  // 재생 중:
  //   원본 source만 사용
  //
  // 정지 중:
  //   AI Preview ON + preview 존재 → preview
  //   아니면 source
  // ============================================================

  String _playbackFrameUrl(XcaFrameRecord frame) {
    return frame.source.url;
  }

  String _displayFrameUrl(XcaFrameRecord frame) {
    if (!_isPlaying && _showAiPreview && frame.preview != null) {
      return frame.preview!.url;
    }

    return frame.source.url;
  }

  // ============================================================
  // STEP 9. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '영상',
      selectedIndex: 4,
      body: Container(
        color: context.appBackground,
        padding: const EdgeInsets.all(16),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detail == null) {
      return _ErrorView(
        message: _error ?? 'XCA Detail을 불러오지 못했습니다.',
        onRetry: _loadDetail,
      );
    }

    return Column(
      children: [
        _buildHeader(context),

        const SizedBox(height: 12),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 220, child: _buildSequencePanel(context)),

              const SizedBox(width: 12),

              Expanded(child: _buildViewerPanel(context)),

              const SizedBox(width: 12),

              SizedBox(width: 250, child: _buildInfoPanel(context)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 10. Header
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final detail = _detail!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined, color: context.appBrand, size: 22),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '관상동맥 조영술 · AI Review',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Patient #${detail.backendPatientId}'
                  '  ·  Examination #${detail.examinationId}'
                  '  ·  Analysis #${detail.analysisId}'
                  '  ·  XCA Detail #${detail.id}',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${detail.sequences.length} Series',
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: '영상 URL 새로고침',
            onPressed: _selectedSequence == null
                ? null
                : () {
                    _loadFrames(_selectedSequence!, preserveCurrentFrame: true);
                  },
            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 11. Sequence Panel
  // ============================================================

  Widget _buildSequencePanel(BuildContext context) {
    final sequences = _detail!.sequences;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: Text(
              'Series',
              style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sequences.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 6);
              },
              itemBuilder: (context, index) {
                final sequence = sequences[index];

                final selected =
                    sequence.sequenceId == _selectedSequence?.sequenceId;

                return Material(
                  color: selected ? context.appSurfaceSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      if (selected) {
                        return;
                      }

                      _loadFrames(sequence);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.appBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sequence.sequenceNo,
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 9),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Series ${sequence.sequenceNo}',
                                  style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  sequence.sideLabel,
                                  style: TextStyle(
                                    color: context.appTextSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${sequence.frameCount} frames',
                                  style: TextStyle(
                                    color: context.appTextSecondary,
                                    fontSize: 9,
                                  ),
                                ),

                                if (sequence
                                    .suspectedFrameIndices
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '의심 ${sequence.suspectedFrameIndices.length} · '
                                    '대표 ${sequence.representativeFrameIndex ?? '-'}',
                                    style: TextStyle(
                                      color: context.appTextSecondary,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 12. Viewer
  // ============================================================

  Widget _buildViewerPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF08131F),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildViewerToolbar(),

          Expanded(child: _buildImageStage()),

          _buildSuspectedFrameBar(),

          _buildReportSelectionBar(),

          _buildFrameControls(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP. Viewer Toolbar
  // ============================================================

  Widget _buildViewerToolbar() {
    final frame = _currentFrame;
    final hasAnnotations = _currentAnnotations.isNotEmpty;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF0D1A28),
      child: Row(
        children: [
          // ======================================================
          // Viewer Title
          // ======================================================
          const Text(
            'XCA Cine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ==================================================
                  // AI View Group
                  // ==================================================
                  _ToolbarGroup(
                    children: [
                      _buildToggleToolbarButton(
                        selected: _showAiPreview,
                        icon: Icons.auto_awesome_outlined,
                        tooltip: 'AI Preview',
                        onPressed: _isPlaying
                            ? null
                            : () {
                                setState(() {
                                  _showAiPreview = !_showAiPreview;
                                });
                              },
                      ),
                      _buildToggleToolbarButton(
                        selected: _showBoundingBox,
                        icon: Icons.crop_free_rounded,
                        tooltip: 'AI BBox',
                        onPressed: () {
                          setState(() {
                            _showBoundingBox = !_showBoundingBox;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // ==================================================
                  // Annotation Tools
                  // ==================================================
                  _ToolbarGroup(
                    children: [
                      _buildAnnotationToolButton(
                        tool: _AngioAnnotationTool.pointer,
                        icon: Icons.near_me_outlined,
                        tooltip: '선택',
                      ),
                      _buildAnnotationToolButton(
                        tool: _AngioAnnotationTool.freehand,
                        icon: Icons.draw_outlined,
                        tooltip: '자유 그리기',
                      ),
                      _buildAnnotationToolButton(
                        tool: _AngioAnnotationTool.rectangle,
                        icon: Icons.crop_square_rounded,
                        tooltip: '사각형',
                      ),
                      _buildAnnotationToolButton(
                        tool: _AngioAnnotationTool.text,
                        icon: Icons.text_fields_rounded,
                        tooltip: '텍스트',
                      ),
                      _buildAnnotationColorPicker(),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // ==================================================
                  // Edit Tools
                  // ==================================================
                  _ToolbarGroup(
                    children: [
                      _buildSimpleToolbarButton(
                        icon: Icons.undo_rounded,
                        tooltip: '마지막 작업 취소',
                        onPressed: hasAnnotations ? _undoAnnotation : null,
                      ),

                      _buildSimpleToolbarButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: '선택 삭제',
                        foregroundColor: Colors.redAccent,
                        selected: _selectedAnnotationId != null,
                        onPressed: _selectedAnnotationId == null
                            ? null
                            : _deleteSelectedAnnotation,
                      ),

                      // 전체 삭제는 Overflow 메뉴로 숨김
                      PopupMenuButton<String>(
                        tooltip: '더보기',
                        padding: EdgeInsets.zero,
                        color: const Color(0xFF182A3E),
                        onSelected: (value) {
                          if (value == 'clear_all' && hasAnnotations) {
                            _clearAnnotations();
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'clear_all',
                              enabled: hasAnnotations,
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.delete_sweep_outlined,
                                    size: 17,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '현재 Frame 전체 삭제',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  _buildAiReactionBadge(frame),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationToolButton({
    required _AngioAnnotationTool tool,
    required IconData icon,
    required String tooltip,
  }) {
    final selected = _annotationTool == tool;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () {
          _setAnnotationTool(tool);
        },
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF2C5F96)
              : Colors.transparent,
          foregroundColor: selected ? Colors.white : Colors.white60,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 17),
      ),
    );
  }

  Widget _buildToggleToolbarButton({
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF2C5F96)
              : Colors.transparent,
          foregroundColor: selected ? Colors.white : Colors.white60,
          disabledForegroundColor: Colors.white24,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 17),
      ),
    );
  }

  Widget _buildSimpleToolbarButton({
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
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, size: 17),
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
                const SizedBox(width: 10),
                const Text('색상 선택'),
              ],
            ),
          );
        }).toList();
      },
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _annotationColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP. AI 반응 상태
  // 고정 폭으로 만들어 Cine 재생 중 Toolbar 흔들림 방지
  // ============================================================

  Widget _buildAiReactionBadge(XcaFrameRecord? frame) {
    final active = frame?.hasAiLocalization ?? false;

    return SizedBox(
      width: 112,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.orangeAccent : Colors.white38,
              ),
            ),

            const SizedBox(width: 6),

            Text(
              active ? 'AI 반응 있음' : 'AI 반응 없음',
              style: TextStyle(
                color: active ? Colors.orangeAccent : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStage() {
    if (_isFrameLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final frame = _currentFrame;

    if (frame == null) {
      return const Center(
        child: Text(
          '표시할 Frame이 없습니다.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final imageUrl = _displayFrameUrl(frame);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sourceWidth = math.max(1, frame.width);
        final sourceHeight = math.max(1, frame.height);

        final scale = math.min(
          constraints.maxWidth / sourceWidth,
          constraints.maxHeight / sourceHeight,
        );

        final displayWidth = sourceWidth * scale;
        final displayHeight = sourceHeight * scale;

        return Center(
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null || _isPlaying) {
                      return child;
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        child,
                        const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                    );
                  },

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      alignment: Alignment.center,
                      color: const Color(0xFF08131F),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '영상을 불러오지 못했습니다.\n'
                            'Signed URL이 만료되었을 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              final sequence = _selectedSequence;

                              if (sequence != null) {
                                _loadFrames(
                                  sequence,
                                  preserveCurrentFrame: true,
                                );
                              }
                            },
                            child: const Text('다시 불러오기'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                if (_showBoundingBox)
                  for (final box in frame.boundingBoxes)
                    Positioned(
                      left: box.x * scale,
                      top: box.y * scale,
                      width: box.width * scale,
                      height: box.height * scale,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.orangeAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                // ======================================================
                // Medical Annotation Layer
                // ======================================================
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      if (_annotationTool == _AngioAnnotationTool.pointer) {
                        _selectAnnotationAt(
                          details,
                          Size(displayWidth, displayHeight),
                        );
                      }
                    },
                    onTapUp: (details) {
                      if (_annotationTool == _AngioAnnotationTool.text) {
                        unawaited(
                          _addTextAnnotation(
                            details.localPosition,
                            Size(displayWidth, displayHeight),
                          ),
                        );
                      }
                    },
                    onPanStart: (details) {
                      _startAnnotationGesture(
                        details,
                        Size(displayWidth, displayHeight),
                      );
                    },
                    onPanUpdate: (details) {
                      _updateAnnotationGesture(
                        details,
                        Size(displayWidth, displayHeight),
                      );
                    },
                    onPanEnd: (_) {
                      _endAnnotationGesture();
                    },
                    onPanCancel: _endAnnotationGesture,
                    child: CustomPaint(
                      painter: _AngioAnnotationPainter(
                        annotations: _currentAnnotations,
                        selectedAnnotationId: _selectedAnnotationId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STEP. AI 의심 프레임 바로가기
  //
  // Backend의 suspected_frame_indices / representative_frame_index를
  // 그대로 사용한다. 값은 List index가 아니라 frame_index이므로
  // 실제 Frame 목록에서 frameIndex를 찾아 이동한다.
  // ============================================================

  Widget _buildSuspectedFrameBar() {
    final sequence = _selectedSequence;

    if (sequence == null || sequence.suspectedFrameIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    final representative = sequence.representativeFrameIndex;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF102033),
        border: Border(top: BorderSide(color: Color(0xFF1E334A))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: Colors.orangeAccent,
          ),

          const SizedBox(width: 6),

          const Text(
            '의심 프레임',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sequence.suspectedFrameIndices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                final frameIndex = sequence.suspectedFrameIndices[index];

                final isRepresentative = representative == frameIndex;

                final isCurrent = _currentFrame?.frameIndex == frameIndex;

                return Tooltip(
                  message: isRepresentative
                      ? '대표 의심 프레임'
                      : '의심 프레임 $frameIndex',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      _jumpToFrameIndexValue(frameIndex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF2C5F96)
                            : isRepresentative
                            ? Colors.orangeAccent.withValues(alpha: 0.13)
                            : const Color(0xFF182A3E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF6EA8E0)
                              : isRepresentative
                              ? Colors.orangeAccent.withValues(alpha: 0.75)
                              : const Color(0xFF30465F),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRepresentative) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            '$frameIndex',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : isRepresentative
                                  ? Colors.orangeAccent
                                  : Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP. 보고서 선택 Frame Bar
  // ============================================================

  Widget _buildReportSelectionBar() {
    if (_selectedReportFrames.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedFrames = _selectedReportFrames.values.toList(growable: false);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1D2D),
        border: Border(top: BorderSide(color: Color(0xFF1E334A))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 15,
            color: Color(0xFF8DB9E8),
          ),

          const SizedBox(width: 6),

          Text(
            '보고서 ${selectedFrames.length}/$_maxReportFrameSelection',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedFrames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                final selected = selectedFrames[index];

                final isCurrent = _currentFrame?.id == selected.frameId;

                return Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF2C5F96)
                        : const Color(0xFF182A3E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF6EA8E0)
                          : const Color(0xFF30465F),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6),
                        ),
                        onTap: () {
                          _openSelectedReportFrame(selected);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            'S${selected.sequenceNo} · F${selected.frameIndex}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(6),
                        ),
                        onTap: () {
                          _removeReportFrame(selected.frameId);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 6),

          Tooltip(
            message: '선택 Frame 전체 해제',
            child: IconButton(
              onPressed: _clearReportFrameSelection,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white54,
                minimumSize: const Size(30, 30),
                maximumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.clear_all_rounded, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 13. Frame Controls
  // ============================================================

  Widget _buildFrameControls() {
    final frame = _currentFrame;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0D1A28),
      child: Row(
        children: [
          IconButton(
            onPressed: _frames.isEmpty ? null : _previousFrame,
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
          ),

          IconButton(
            tooltip: _isPreparingPlayback
                ? '영상 준비 중'
                : _isPlaying
                ? '일시정지'
                : '재생',
            onPressed: _frames.length <= 1 || _isPreparingPlayback
                ? null
                : _togglePlayback,
            icon: _isPreparingPlayback
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
          ),

          IconButton(
            onPressed: _frames.isEmpty ? null : _nextFrame,
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Slider(
              value: _frames.isEmpty ? 0 : _currentIndex.toDouble(),
              min: 0,
              max: math.max(0, _frames.length - 1).toDouble(),
              divisions: _frames.length <= 1 ? null : _frames.length - 1,
              onChanged: _frames.length <= 1
                  ? null
                  : (value) {
                      _setCurrentIndex(value.round());
                    },
            ),
          ),

          const SizedBox(width: 8),

          Text(
            frame == null
                ? '- / -'
                : 'Frame ${frame.frameIndex}'
                      '  ·  '
                      '${_currentIndex + 1}/${_frames.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 9.5),
          ),

          const SizedBox(width: 12),

          DropdownButton<double>(
            value: _playbackSpeed,
            dropdownColor: const Color(0xFF132235),
            style: const TextStyle(color: Colors.white, fontSize: 10),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 0.5, child: Text('0.5×')),
              DropdownMenuItem(value: 1.0, child: Text('1.0×')),
              DropdownMenuItem(value: 2.0, child: Text('2.0×')),
            ],
            onChanged: (value) {
              if (value != null) {
                _changePlaybackSpeed(value);
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 14. Info Panel
  // ============================================================

  Widget _buildInfoPanel(BuildContext context) {
    final frame = _currentFrame;
    final sequence = _selectedSequence;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: ListView(
        children: [
          Text(
            '영상 정보',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 14),

          _InfoRow(label: 'Series', value: sequence?.sequenceNo ?? '-'),

          _InfoRow(label: '측', value: sequence?.sideLabel ?? '-'),

          _InfoRow(
            label: 'Sequence ID',
            value: sequence == null ? '-' : '#${sequence.sequenceId}',
          ),

          _InfoRow(
            label: 'Frame ID',
            value: frame == null ? '-' : '#${frame.id}',
          ),

          _InfoRow(
            label: 'Frame Index',
            value: frame?.frameIndex.toString() ?? '-',
          ),

          _InfoRow(
            label: '크기',
            value: frame == null ? '-' : '${frame.width} × ${frame.height}',
          ),

          _InfoRow(
            label: '대표 Frame',
            value: sequence?.representativeFrameIndex?.toString() ?? '-',
          ),

          _InfoRow(
            label: '의심 Frame',
            value: sequence == null
                ? '-'
                : '${sequence.suspectedFrameIndices.length}개',
          ),

          _InfoRow(
            label: '보고서 선택',
            value: '${_selectedReportFrames.length}/$_maxReportFrameSelection',
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: frame == null
                  ? null
                  : _toggleCurrentFrameReportSelection,
              style: OutlinedButton.styleFrom(
                foregroundColor: _isCurrentFrameSelectedForReport
                    ? const Color(0xFF8DB9E8)
                    : context.appTextPrimary,
                side: BorderSide(
                  color: _isCurrentFrameSelectedForReport
                      ? const Color(0xFF6EA8E0)
                      : context.appBorder,
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
              icon: Icon(
                _isCurrentFrameSelectedForReport
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 16,
              ),
              label: Text(
                _isCurrentFrameSelectedForReport
                    ? '보고서 선택 해제'
                    : '현재 Frame 보고서 선택',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedReportFrames.isEmpty || _isSavingReport
                  ? null
                  : _openReportDraftDialog,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: _isSavingReport
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined, size: 16),
              label: Text(
                _isSavingReport ? '저장 중...' : '보고서 초안 작성',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          if (_lastSavedReportVersion != null) ...[
            const SizedBox(height: 8),

            _InfoRow(
              label: '최근 저장',
              value:
                  'v${_lastSavedReportVersion!.versionNo} '
                  '#${_lastSavedReportVersion!.id}',
            ),

            const SizedBox(height: 2),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingReportPdf
                    ? null
                    : _openSavedReportPdfPreview,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                icon: _isLoadingReportPdf
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(
                  _isLoadingReportPdf ? 'PDF 불러오는 중...' : 'Draft PDF 미리보기',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          Text(
            'Annotation',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          _InfoRow(label: '도구', value: _annotationToolLabel),

          _InfoRow(label: '현재 Frame', value: '${_currentAnnotations.length}개'),

          _InfoRow(
            label: '선택',
            value: _selectedAnnotationId == null ? '-' : '1개',
          ),

          const SizedBox(height: 8),

          Text(
            '현재 Annotation은 Viewer 세션 내 Frame 단위 임시 표시입니다. '
            '보고서에는 선택한 보존 Frame과 의료진 의견만 저장되며, '
            'Annotation 도형 자체는 아직 서버에 저장되지 않습니다.',
            style: TextStyle(
              color: context.appTextSecondary,
              height: 1.45,
              fontSize: 8.5,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'AI Localization',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          _InfoRow(
            label: '상태',
            value: frame == null
                ? '-'
                : frame.hasAiLocalization
                ? '협착 의심 반응'
                : '반응 없음',
          ),

          _InfoRow(
            label: 'BBox',
            value: frame == null ? '-' : '${frame.boundingBoxes.length}개',
          ),

          _InfoRow(
            label: 'Soft max',
            value: frame?.softMax == null
                ? '-'
                : frame!.softMax!.toStringAsFixed(4),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'AI 표시 영역은 '
              'weak localization 기반의 '
              '협착 의심 영역입니다.\n'
              '확정 병변 위치 또는 협착률로 '
              '해석하지 않습니다.',
              style: TextStyle(
                color: context.appTextSecondary,
                height: 1.55,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP. XCA 보고서 초안 작성 Dialog
// ============================================================

class _XcaReportDraftDialog extends StatefulWidget {
  final int examinationId;
  final int detailId;
  final int aiResultId;
  final List<_SelectedReportFrame> selectedFrames;

  const _XcaReportDraftDialog({
    required this.examinationId,
    required this.detailId,
    required this.aiResultId,
    required this.selectedFrames,
  });

  @override
  State<_XcaReportDraftDialog> createState() => _XcaReportDraftDialogState();
}

class _XcaReportDraftDialogState extends State<_XcaReportDraftDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String? _validationMessage;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        _validationMessage = '의료진 의견을 입력해주세요.';
      });
      return;
    }

    if (value.length > 4000) {
      setState(() {
        _validationMessage = '의료진 의견은 4000자 이하로 입력해주세요.';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('2D XCA 보고서 초안'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text('검사 #${widget.examinationId}'),
                  Text('XCA Detail #${widget.detailId}'),
                  Text('AI Result #${widget.aiResultId}'),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                '선택 Frame ${widget.selectedFrames.length}개',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.selectedFrames
                    .map((frame) {
                      return Chip(
                        label: Text(
                          'S${frame.sequenceNo} · '
                          'F${frame.frameIndex}',
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    })
                    .toList(growable: false),
              ),

              const SizedBox(height: 16),

              const Text(
                '의료진 의견',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 4,
                maxLines: 7,
                maxLength: 4000,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'AI 참고 결과와 선택 Frame을 검토한 의료진 의견을 입력하세요.',
                  border: const OutlineInputBorder(),
                  errorText: _validationMessage,
                ),
                onChanged: (_) {
                  if (_validationMessage != null) {
                    setState(() {
                      _validationMessage = null;
                    });
                  }
                },
                onSubmitted: (_) {
                  _submit();
                },
              ),

              const SizedBox(height: 4),

              Text(
                '선택한 보존 Frame과 의료진 의견이 '
                '새 ReportVersion 초안으로 저장됩니다. '
                '현재 Viewer Annotation 도형은 포함되지 않습니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined, size: 17),
          label: const Text('보고서 초안에 저장'),
        ),
      ],
    );
  }
}

// ============================================================
// STEP. 보고서 선택 Frame
// ============================================================

class _SelectedReportFrame {
  final int frameId;
  final int sequenceId;
  final String sequenceNo;
  final int frameIndex;
  final String sideLabel;

  const _SelectedReportFrame({
    required this.frameId,
    required this.sequenceId,
    required this.sequenceNo,
    required this.frameIndex,
    required this.sideLabel,
  });
}

// ============================================================
// STEP. Toolbar Group
// ============================================================

class _ToolbarGroup extends StatelessWidget {
  final List<Widget> children;

  const _ToolbarGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF132235),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263B52)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ============================================================
// STEP 15. Info Row
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(color: context.appTextSecondary, fontSize: 9.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.appTextPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 16. Error View
// ============================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 38,
            color: Theme.of(context).colorScheme.error,
          ),

          const SizedBox(height: 10),

          Text(
            'ANGIO 영상을 불러오지 못했습니다.',
            style: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextSecondary, fontSize: 10),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// STEP. Text Annotation Dialog
//
// TextEditingController와 FocusNode를 Dialog 자체 State가 소유한다.
// Navigator.pop 직후 부모 Viewer가 controller를 먼저 dispose하는
// lifecycle race를 피한다.
// ============================================================

class _TextAnnotationDialog extends StatefulWidget {
  const _TextAnnotationDialog();

  @override
  State<_TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<_TextAnnotationDialog> {
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
        decoration: const InputDecoration(hintText: '영상에 표시할 메모를 입력하세요.'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }
}

// ============================================================
// STEP. Annotation Model
// ============================================================

enum _AngioAnnotationTool { pointer, freehand, rectangle, text }

enum _AngioAnnotationType { freehand, rectangle, text }

class _AngioAnnotation {
  final String id;
  final _AngioAnnotationType type;
  final Color color;

  final List<Offset> points;

  final Offset? start;
  Offset? end;

  final Offset? position;
  final String? text;

  _AngioAnnotation._({
    required this.id,
    required this.type,
    required this.color,
    this.points = const <Offset>[],
    this.start,
    this.end,
    this.position,
    this.text,
  });

  factory _AngioAnnotation.freehand({
    required String id,
    required Color color,
    required List<Offset> points,
  }) {
    return _AngioAnnotation._(
      id: id,
      type: _AngioAnnotationType.freehand,
      color: color,
      points: points,
    );
  }

  factory _AngioAnnotation.rectangle({
    required String id,
    required Color color,
    required Offset start,
    required Offset end,
  }) {
    return _AngioAnnotation._(
      id: id,
      type: _AngioAnnotationType.rectangle,
      color: color,
      start: start,
      end: end,
    );
  }

  factory _AngioAnnotation.text({
    required String id,
    required Color color,
    required Offset position,
    required String text,
  }) {
    return _AngioAnnotation._(
      id: id,
      type: _AngioAnnotationType.text,
      color: color,
      position: position,
      text: text,
    );
  }
}

// ============================================================
// STEP. Medical Annotation Painter
// ============================================================

class _AngioAnnotationPainter extends CustomPainter {
  final List<_AngioAnnotation> annotations;
  final String? selectedAnnotationId;

  const _AngioAnnotationPainter({
    required this.annotations,
    required this.selectedAnnotationId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final selected = annotation.id == selectedAnnotationId;

      switch (annotation.type) {
        case _AngioAnnotationType.freehand:
          _paintFreehand(canvas, size, annotation, selected);
          break;

        case _AngioAnnotationType.rectangle:
          _paintRectangle(canvas, size, annotation, selected);
          break;

        case _AngioAnnotationType.text:
          _paintText(canvas, size, annotation, selected);
          break;
      }
    }
  }

  void _paintFreehand(
    Canvas canvas,
    Size size,
    _AngioAnnotation annotation,
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
    _AngioAnnotation annotation,
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
    _AngioAnnotation annotation,
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
  bool shouldRepaint(covariant _AngioAnnotationPainter oldDelegate) {
    return true;
  }
}
