import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../data/services/ai_analysis_service.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. CCTA / Clinical 공용 결과보고서
//
// CCTA:
// AI Result -> MedicalResult(CCTA_3D) -> Conclusion -> Signoff
// -> Signed PDF -> Patient Release
//
// Clinical:
// 동일 흐름. Flutter는 report_type=CLINICAL까지 구현.
// 2026-09-26 확인 당시 Backend create serializer는
// XCA_2D / CCTA_3D만 허용했으므로 Backend 확장이 필요할 수 있다.
// ============================================================

enum AiMedicalReportKind { ccta, clinical }

extension AiMedicalReportKindX on AiMedicalReportKind {
  String get backendType => switch (this) {
    AiMedicalReportKind.ccta => 'CCTA_3D',
    AiMedicalReportKind.clinical => 'CLINICAL',
  };

  String get title => switch (this) {
    AiMedicalReportKind.ccta => '3D CCTA 결과보고서',
    AiMedicalReportKind.clinical => 'Clinical AI 결과보고서',
  };
}

class AiMedicalReportDetail {
  final int id;
  final String reportType;
  final String status;
  final String conclusion;
  final int? latestReportId;
  final String? signedBy;
  final DateTime? signedAt;
  final DateTime? releasedAt;
  final int? previewFileId;
  final int? overlayFileId;

  const AiMedicalReportDetail({
    required this.id,
    required this.reportType,
    required this.status,
    required this.conclusion,
    required this.latestReportId,
    required this.signedBy,
    required this.signedAt,
    required this.releasedAt,
    required this.previewFileId,
    required this.overlayFileId,
  });

  bool get isSigned {
    final value = status.toUpperCase();
    return value == 'SIGNED' || value == 'RELEASED';
  }

  bool get isReleased => status.toUpperCase() == 'RELEASED';

  factory AiMedicalReportDetail.fromJson(Map<String, dynamic> json) {
    final workflow = _map(json['workflow']);
    final summaries = _map(json['ai_summaries'] ?? json['aiSummaries']);
    final ccta = _map(summaries['ccta'] ?? summaries['CCTA']);

    final id = _int(
      json['medical_result_id'] ?? json['medicalResultId'] ?? json['id'],
    );
    if (id == null || id < 1) {
      throw const FormatException('MedicalResult ID가 없는 응답입니다.');
    }

    return AiMedicalReportDetail(
      id: id,
      reportType: (json['report_type'] ?? json['reportType'])?.toString() ?? '',
      status: (workflow['status'] ?? json['status'])?.toString() ?? '',
      conclusion: json['conclusion']?.toString() ?? '',
      latestReportId: _int(
        workflow['latest_report_id'] ??
            workflow['latestReportId'] ??
            json['latest_report_id'] ??
            json['latestReportId'],
      ),
      signedBy: (workflow['signed_by'] ?? workflow['signedBy'])?.toString(),
      signedAt: _date(workflow['signed_at'] ?? workflow['signedAt']),
      releasedAt: _date(workflow['released_at'] ?? workflow['releasedAt']),
      previewFileId: _int(
        ccta['preview_file_asset_id'] ?? ccta['previewFileAssetId'],
      ),
      overlayFileId: _int(
        ccta['overlay_file_asset_id'] ?? ccta['overlayFileAssetId'],
      ),
    );
  }
}

class AiMedicalReportException implements Exception {
  final String message;
  const AiMedicalReportException(this.message);
  @override
  String toString() => message;
}

// ============================================================
// STEP 2. API Service
// ============================================================

class AiMedicalReportService {
  final dynamic apiClient;
  const AiMedicalReportService({required this.apiClient});

  Future<AiMedicalReportDetail> prepare({
    required AiResultUiModel result,
    required int patientId,
    required AiMedicalReportKind kind,
  }) async {
    if (result.id < 1) {
      throw const AiMedicalReportException('실제 AI Result를 먼저 불러와주세요.');
    }

    try {
      final response = await apiClient.dio.post(
        '/examinations/${result.examinationId}/medical-results/',
        data: {
          'patient_id': patientId,
          'report_type': kind.backendType,
          'analysis_result_id': result.id,
        },
      );

      final outer = _responseMap(response.data);
      final medical = _map(outer['medical_result']);
      final id = _int(medical['id'] ?? outer['medical_result_id']);
      if (id == null || id < 1) {
        throw const AiMedicalReportException('MedicalResult ID를 확인할 수 없습니다.');
      }
      return fetch(id);
    } on AiMedicalReportException {
      rethrow;
    } on DioException catch (error) {
      var message = _dioMessage(error, '${kind.title} 초안을 준비하지 못했습니다.');
      if (kind == AiMedicalReportKind.clinical &&
          error.response?.statusCode == 400) {
        message += '\n\nBackend에서 report_type=CLINICAL 생성 지원 여부를 확인해주세요.';
      }
      throw AiMedicalReportException(message);
    }
  }

  Future<AiMedicalReportDetail> fetch(int id) async {
    try {
      final response = await apiClient.dio.get('/medical-results/$id/');
      return AiMedicalReportDetail.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw AiMedicalReportException(
        _dioMessage(error, 'MedicalResult를 불러오지 못했습니다.'),
      );
    }
  }

  Future<AiMedicalReportDetail> saveConclusion(
    int id,
    String conclusion,
  ) async {
    final value = conclusion.trim();
    if (value.isEmpty) {
      throw const AiMedicalReportException('의료진 최종 소견을 입력해주세요.');
    }
    if (value.length > 4000) {
      throw const AiMedicalReportException('의료진 최종 소견은 4000자 이하로 입력해주세요.');
    }

    try {
      await apiClient.dio.patch(
        '/medical-results/$id/',
        data: {'conclusion': value},
      );
      return fetch(id);
    } on DioException catch (error) {
      throw AiMedicalReportException(
        _dioMessage(error, '의료진 최종 소견을 저장하지 못했습니다.'),
      );
    }
  }

  Future<AiMedicalReportDetail> signoff(int id, String conclusion) async {
    try {
      final response = await apiClient.dio.post(
        '/medical-results/$id/signoff/',
        data: {'conclusion': conclusion.trim()},
      );
      return AiMedicalReportDetail.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw AiMedicalReportException(
        _dioMessage(error, '최종 승인 및 서명을 완료하지 못했습니다.'),
      );
    }
  }

  Future<AiMedicalReportDetail> release(int id) async {
    try {
      final response = await apiClient.dio.post(
        '/medical-results/$id/release/',
      );
      return AiMedicalReportDetail.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw AiMedicalReportException(_dioMessage(error, '환자 공개를 완료하지 못했습니다.'));
    }
  }

  Future<Uint8List> fileBytes(int fileId) async {
    try {
      final response = await apiClient.dio.get('/files/$fileId/download/');
      final data = _responseMap(response.data);
      final url = _downloadUrl(data);
      if (url == null) {
        throw const AiMedicalReportException('파일 다운로드 URL이 없습니다.');
      }
      return _download(url);
    } on AiMedicalReportException {
      rethrow;
    } on DioException catch (error) {
      throw AiMedicalReportException(
        _dioMessage(error, 'FileAsset #$fileId를 불러오지 못했습니다.'),
      );
    }
  }

  Future<Uint8List> pdfBytes(int reportId) async {
    try {
      final response = await apiClient.dio.get('/reports/$reportId/download/');
      final data = _responseMap(response.data);
      final status =
          (data['download_integration_status'] ??
                  data['downloadIntegrationStatus'])
              ?.toString();
      if (status != null && status.isNotEmpty && status != 'CONFIGURED') {
        throw AiMedicalReportException('PDF 저장소 연결 상태: $status');
      }
      final url = _downloadUrl(data);
      if (url == null) {
        throw const AiMedicalReportException('PDF 다운로드 URL이 없습니다.');
      }
      final bytes = await _download(url);
      if (bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        throw const AiMedicalReportException('서버 응답이 PDF 형식이 아닙니다.');
      }
      return bytes;
    } on AiMedicalReportException {
      rethrow;
    } on DioException catch (error) {
      throw AiMedicalReportException(
        _dioMessage(error, 'Signed PDF를 불러오지 못했습니다.'),
      );
    }
  }

  Future<Uint8List> _download(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      throw const AiMedicalReportException('다운로드 URL 형식이 올바르지 않습니다.');
    }

    final Response<List<int>> response;
    if (uri.hasScheme) {
      response = await Dio().get<List<int>>(
        rawUrl,
        options: Options(responseType: ResponseType.bytes),
      );
    } else {
      response = await apiClient.dio.get<List<int>>(
        rawUrl,
        options: Options(responseType: ResponseType.bytes),
      );
    }
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const AiMedicalReportException('다운로드된 파일이 비어 있습니다.');
    }
    return Uint8List.fromList(data);
  }
}

// ============================================================
// STEP 3. Report Page
// ============================================================

class AiMedicalReportPage extends StatefulWidget {
  final AiResultUiModel result;
  const AiMedicalReportPage({super.key, required this.result});

  @override
  State<AiMedicalReportPage> createState() => _AiMedicalReportPageState();
}

class _AiMedicalReportPageState extends State<AiMedicalReportPage> {
  AiAnalysisService? _aiService;
  AiMedicalReportService? _service;
  AiAnalysisPatientContextRecord? _patient;
  AiMedicalReportDetail? _detail;

  final TextEditingController _conclusion = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _saved = false;
  bool _confirmed = false;
  String? _error;
  Uint8List? _previewBytes;
  Uint8List? _overlayBytes;

  AiMedicalReportKind get _kind => widget.result.analysisType == 'CCTA'
      ? AiMedicalReportKind.ccta
      : AiMedicalReportKind.clinical;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service != null) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final api = auth.authService.apiClient;
    _aiService = AiAnalysisService(apiClient: api);
    _service = AiMedicalReportService(apiClient: api);
    _loadPatient();
  }

  @override
  void dispose() {
    _conclusion.dispose();
    super.dispose();
  }

  Future<void> _loadPatient() async {
    try {
      final value = await _aiService!.fetchPatientContext(
        widget.result.examinationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _patient = value;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '환자 정보를 불러오지 못했습니다. $error';
      });
    }
  }

  Future<void> _run(Future<void> Function() body) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } on AiMedicalReportException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _apply(AiMedicalReportDetail detail) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _detail = detail;
      _conclusion.text = detail.conclusion;
      _saved = detail.conclusion.trim().isNotEmpty;
    });

    if (_kind == AiMedicalReportKind.ccta) {
      Uint8List? preview;
      Uint8List? overlay;
      if (detail.previewFileId != null) {
        try {
          preview = await _service!.fileBytes(detail.previewFileId!);
        } catch (_) {}
      }
      if (detail.overlayFileId != null) {
        try {
          overlay = await _service!.fileBytes(detail.overlayFileId!);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _previewBytes = preview;
          _overlayBytes = overlay;
        });
      }
    }
  }

  void _prepare() {
    final patient = _patient;
    if (patient == null) {
      return;
    }
    _run(() async {
      final detail = await _service!.prepare(
        result: widget.result,
        patientId: patient.patientId,
        kind: _kind,
      );
      await _apply(detail);
    });
  }

  void _save() {
    final detail = _detail;
    if (detail == null || detail.isSigned) {
      return;
    }
    _run(() async {
      final next = await _service!.saveConclusion(detail.id, _conclusion.text);
      await _apply(next);
      if (mounted) {
        setState(() {
          _saved = true;
          _confirmed = false;
        });
        _message('의료진 최종 소견을 저장했습니다.');
      }
    });
  }

  void _sign() {
    final detail = _detail;
    if (detail == null || !_saved || !_confirmed || detail.isSigned) {
      return;
    }
    _run(() async {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('${_kind.title} 최종 승인'),
          content: const Text(
            'AI 결과와 의료진 최종 소견을 모두 검토했는지 확인해주세요.\n\n'
            '최종 승인하면 Backend에 등록된 현재 의료진 서명이 Signoff에 연결되고 Signed PDF가 생성됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('검토 승인 · 최종 서명'),
            ),
          ],
        ),
      );
      if (!mounted || ok != true) {
        return;
      }

      final next = await _service!.signoff(detail.id, _conclusion.text);
      await _apply(next);
      if (!next.isSigned) {
        throw const AiMedicalReportException('SIGNED 상태를 확인하지 못했습니다.');
      }
      if (mounted) {
        _message('최종 승인 및 Signed PDF 생성이 완료되었습니다.');
      }
      if (next.latestReportId != null) {
        await _openPdf(next.latestReportId!);
      }
    });
  }

  void _release() {
    final detail = _detail;
    if (detail == null || !detail.isSigned || detail.isReleased) {
      return;
    }
    _run(() async {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('환자에게 결과를 공개할까요?'),
          content: const Text('최종 승인된 Signed PDF와 의료 결과가 환자 공개 상태로 전환됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('환자에게 공개'),
            ),
          ],
        ),
      );
      if (!mounted || ok != true) {
        return;
      }
      final next = await _service!.release(detail.id);
      await _apply(next);
      if (mounted) {
        _message('환자 공개가 완료되었습니다.');
      }
    });
  }

  Future<void> _openPdf(int reportId) async {
    try {
      final bytes = await _service!.pdfBytes(reportId);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ReportPdfPage(
            bytes: bytes,
            title: '${_kind.title} · Signed PDF',
          ),
        ),
      );
    } on AiMedicalReportException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final patient = _patient;
    final username =
        context.watch<AuthProvider>().currentUser?.username ?? '현재 의료진';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _kind.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '검사 #${widget.result.examinationId} · Analysis #${widget.result.analysisId} · Result #${widget.result.id}',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patient == null
          ? _ErrorBox(_error ?? '환자 정보를 확인할 수 없습니다.')
          : Row(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Card(
                        title: '보고서 대상',
                        icon: Icons.person_outline,
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            _Info(
                              '환자',
                              '${patient.name} (#${patient.patientId})',
                            ),
                            _Info('검사', '#${widget.result.examinationId}'),
                            _Info('AI Result', '#${widget.result.id}'),
                            _Info(
                              'MedicalResult',
                              detail == null ? '-' : '#${detail.id}',
                            ),
                            _Info('상태', detail?.status ?? '초안 준비 전'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _kind == AiMedicalReportKind.ccta
                          ? _cctaSummary()
                          : _clinicalSummary(),
                      if (detail != null) ...[
                        const SizedBox(height: 12),
                        _Card(
                          title: '의료진 최종 소견',
                          icon: Icons.edit_note_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _conclusion,
                                enabled: !_busy && !detail.isSigned,
                                minLines: 4,
                                maxLines: 7,
                                maxLength: 4000,
                                decoration: const InputDecoration(
                                  hintText: 'AI 분석 결과를 검토한 의료진의 최종 소견을 입력하세요.',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  if (_saved) {
                                    setState(() {
                                      _saved = false;
                                      _confirmed = false;
                                    });
                                  }
                                },
                              ),
                              if (!detail.isSigned)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed:
                                        _busy || _conclusion.text.trim().isEmpty
                                        ? null
                                        : _save,
                                    icon: const Icon(
                                      Icons.save_outlined,
                                      size: 17,
                                    ),
                                    label: Text(_saved ? '소견 저장 완료' : '소견 저장'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          title: '최종 PDF · 의료진 서명',
                          icon: Icons.verified_outlined,
                          child: detail.isSigned
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.isReleased
                                          ? '최종 승인 및 환자 공개 완료'
                                          : '최종 승인 완료 · SIGNED',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (detail.signedBy != null)
                                      Text(
                                        '승인 의료진 ${detail.signedBy}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: context.appTextSecondary,
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _confirmed,
                                      onChanged: _busy || !_saved
                                          ? null
                                          : (v) => setState(
                                              () => _confirmed = v == true,
                                            ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: const Text(
                                        'AI 결과와 의료진 소견을 확인했고 최종 승인에 동의합니다.',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.appSurfaceSoft,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: context.appBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.draw_outlined,
                                            color: context.appBrand,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '$username 계정의 Backend 등록 서명을 최종 Signoff와 PDF에 사용합니다.',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                height: 1.45,
                                                color: context.appTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed:
                                            _busy || !_saved || !_confirmed
                                            ? null
                                            : _sign,
                                        icon: const Icon(
                                          Icons.verified_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _busy
                                              ? '최종 승인 중...'
                                              : '검토 승인 · 최종 서명 · PDF 생성',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBox(_error!),
                      ],
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '보고서 Workflow',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Step('환자', '#${patient.patientId}', true),
                        _Step(
                          'AI 결과',
                          '#${widget.result.id}',
                          widget.result.id > 0,
                        ),
                        _Step(
                          'MedicalResult',
                          detail == null ? '준비 전' : '#${detail.id}',
                          detail != null,
                        ),
                        _Step('의료진 소견', _saved ? '저장 완료' : '저장 필요', _saved),
                        _Step(
                          '최종 승인',
                          detail?.isSigned == true ? 'SIGNED' : '대기',
                          detail?.isSigned == true,
                        ),
                        _Step(
                          '환자 공개',
                          detail?.isReleased == true ? 'RELEASED' : '대기',
                          detail?.isReleased == true,
                        ),
                        const Spacer(),
                        if (detail == null)
                          FilledButton.icon(
                            onPressed: _busy ? null : _prepare,
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 18,
                            ),
                            label: Text(_busy ? '초안 준비 중...' : '보고서 초안 생성/열기'),
                          ),
                        if (detail?.latestReportId != null)
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _openPdf(detail!.latestReportId!),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                            label: const Text('Signed PDF 열기'),
                          ),
                        if (detail != null &&
                            detail.isSigned &&
                            !detail.isReleased) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _busy ? null : _release,
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('환자에게 공개'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cctaSummary() {
    final detail = _detail;
    final items = widget.result.segmentationDetails;
    final cac = widget.result.cacScore;
    return Column(
      children: [
        _Card(
          title: 'CCTA AI 분석 요약',
          icon: Icons.view_in_ar_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.result.summary,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final item in items)
                _RowValue(
                  item.structureName,
                  item.volumeMm3 == null
                      ? 'Mesh #${item.meshFileAssetId ?? '-'}'
                      : '${item.volumeMm3!.toStringAsFixed(1)} mm³',
                ),
              if (cac != null)
                _RowValue(
                  'CAC Total',
                  cac.total.toStringAsFixed(0),
                  bold: true,
                ),
            ],
          ),
        ),
        if (detail != null &&
            (detail.previewFileId != null || detail.overlayFileId != null)) ...[
          const SizedBox(height: 12),
          _Card(
            title: '보고서 포함 이미지',
            icon: Icons.image_outlined,
            child: Row(
              children: [
                Expanded(
                  child: _ImageBox(
                    '3D 석회화 Preview',
                    detail.previewFileId,
                    _previewBytes,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ImageBox(
                    '원본 CT Overlay',
                    detail.overlayFileId,
                    _overlayBytes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _clinicalSummary() {
    final json = widget.result.resultJson;
    final prediction = _int(json['prediction']);
    final probability = _double(json['probability']);
    final threshold = _double(json['threshold']);
    final explanation = _map(json['explanation']);
    final top = explanation['top_features'] is List
        ? (explanation['top_features'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    return Column(
      children: [
        _Card(
          title: 'Clinical AI 위험 예측',
          icon: Icons.monitor_heart_outlined,
          child: Column(
            children: [
              _RowValue(
                'AI 예측',
                prediction == 1
                    ? 'CAD 위험 신호 있음'
                    : prediction == 0
                    ? 'CAD 위험 신호 낮음'
                    : '-',
                bold: true,
              ),
              _RowValue(
                '예측 확률',
                probability == null
                    ? '-'
                    : '${(probability * 100).toStringAsFixed(1)}%',
              ),
              _RowValue(
                '판단 기준',
                threshold == null
                    ? '-'
                    : '${(threshold * 100).toStringAsFixed(1)}%',
              ),
              _RowValue(
                'Confidence',
                widget.result.confidence == null
                    ? '-'
                    : '${(widget.result.confidence! * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'TreeSHAP 주요 기여 변수',
          icon: Icons.psychology_alt_outlined,
          child: top.isEmpty
              ? Text(
                  'XAI 설명 데이터가 없습니다.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextSecondary,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < top.length; i++)
                      _RowValue(
                        '${i + 1}. ${top[i]['feature'] ?? '-'}',
                        _shap(top[i]['shap_value']),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Clinical AI 결과는 CAD 위험 예측 보조 자료이며 확진을 의미하지 않습니다. 의료진은 임상 정보, 혈액검사 및 영상 결과를 함께 검토해 최종 소견을 작성합니다.',
            style: TextStyle(
              fontSize: 9.5,
              height: 1.5,
              color: context.appTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 4. PDF Page
// ============================================================

class _ReportPdfPage extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  const _ReportPdfPage({required this.bytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: 'medical-report.pdf',
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
      ),
    );
  }
}

// ============================================================
// STEP 5. UI Helpers
// ============================================================

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: context.appBrand),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label ',
        style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.appTextPrimary,
        ),
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  final String label;
  final String value;
  final bool done;
  const _Step(this.label, this.value, this.done);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 15,
          color: done ? context.appBrand : context.appTextSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: context.appTextPrimary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: context.appTextSecondary,
          ),
        ),
      ],
    ),
  );
}

class _RowValue extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _RowValue(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: context.appTextPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: context.appTextPrimary,
          ),
        ),
      ],
    ),
  );
}

class _ImageBox extends StatelessWidget {
  final String label;
  final int? fileId;
  final Uint8List? bytes;
  const _ImageBox(this.label, this.fileId, this.bytes);
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(10),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: context.appSurfaceSoft,
          child: Text(
            '$label${fileId == null ? '' : ' · #$fileId'}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: bytes == null
              ? Center(
                  child: Text(
                    fileId == null ? '저장된 이미지가 없습니다.' : '이미지를 불러오지 못했습니다.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.appTextSecondary,
                    ),
                  ),
                )
              : Image.memory(
                  bytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
        ),
      ],
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      style: TextStyle(
        fontSize: 10,
        height: 1.5,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    ),
  );
}

// ============================================================
// STEP 6. Parsing Helpers
// ============================================================

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
int? _int(dynamic value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '');
double? _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

Map<String, dynamic> _responseMap(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw const FormatException('API 응답 형식이 올바르지 않습니다.');
}

String? _downloadUrl(Map<String, dynamic> data) {
  final value =
      data['download_url'] ??
      data['downloadUrl'] ??
      data['signed_url'] ??
      data['signedUrl'] ??
      data['url'];
  return value == null || value.toString().trim().isEmpty
      ? null
      : value.toString().trim();
}

String _dioMessage(DioException error, String fallback) {
  dynamic data = error.response?.data;
  if (data is List<int>) {
    try {
      data = jsonDecode(utf8.decode(data));
    } catch (_) {
      data = null;
    }
  }
  if (data is Map) {
    final detail = data['detail'];
    if (detail != null && detail.toString().trim().isNotEmpty) {
      return detail.toString();
    }
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }
  }
  return fallback;
}

String _shap(dynamic value) {
  final number = _double(value);
  if (number == null) {
    return '-';
  }
  return '${number >= 0 ? '↑' : '↓'} ${number.abs().toStringAsFixed(4)}';
}
