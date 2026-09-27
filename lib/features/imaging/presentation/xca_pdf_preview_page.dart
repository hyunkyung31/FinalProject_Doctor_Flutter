import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../data/models/xca_report_models.dart';
import '../data/services/xca_report_service.dart';

// ============================================================
// STEP 1. XCA PDF Preview Page
//
// Draft 확인
// → 의료진 재인증
// → 최종 확정 / Signed PDF 생성
// → Signed PDF 확인
// → 환자 공개
// ============================================================

class XcaPdfPreviewPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String? contentSha256;
  final bool initiallySigned;

  final int versionId;
  final int versionNo;
  final int patientId;
  final int medicalResultId;

  const XcaPdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.contentSha256,
    required this.initiallySigned,
    required this.versionId,
    required this.versionNo,
    required this.patientId,
    required this.medicalResultId,
  });

  @override
  State<XcaPdfPreviewPage> createState() => _XcaPdfPreviewPageState();
}

class _XcaPdfPreviewPageState extends State<XcaPdfPreviewPage> {
  XcaReportService? _service;

  late Uint8List _pdfBytes;
  String? _contentSha256;

  late bool _isSigned;
  bool _isReleased = false;

  bool _isFinalizing = false;
  bool _isReleasing = false;
  bool _isRefreshingPdf = false;

  bool get _isBusy => _isFinalizing || _isReleasing || _isRefreshingPdf;

  @override
  void initState() {
    super.initState();

    _pdfBytes = widget.pdfBytes;
    _contentSha256 = widget.contentSha256;
    _isSigned = widget.initiallySigned;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_service != null) {
      return;
    }

    final auth = context.read<AuthProvider>();

    _service = XcaReportService(apiClient: auth.authService.apiClient);
  }

  // ============================================================
  // STEP 2. PDF 최신화
  //
  // Finalize 성공 후 같은 endpoint를 다시 조회하면
  // Backend가 XCAFinalPDF를 찾아 Signed PDF를 반환한다.
  // ============================================================

  Future<XcaPdfDocument?> _reloadPdf({bool showError = true}) async {
    final service = _service;

    if (service == null) {
      return null;
    }

    if (mounted) {
      setState(() {
        _isRefreshingPdf = true;
      });
    }

    try {
      final document = await service.fetchXcaPdfDocument(
        versionId: widget.versionId,
        patientId: widget.patientId,
      );

      if (!mounted) {
        return document;
      }

      setState(() {
        _pdfBytes = document.bytes;

        if (document.contentSha256 != null) {
          _contentSha256 = document.contentSha256;
        }

        if (document.isSigned) {
          _isSigned = true;
        }
      });

      return document;
    } on XcaReportException catch (error) {
      if (showError && mounted) {
        _showMessage(error.message);
      }

      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 3. 5분 재인증 Token 확보
  //
  // AuthProvider에 유효한 Token이 있으면 재사용하고,
  // 없을 때만 비밀번호를 입력받는다.
  // ============================================================

  Future<String?> _resolveReauthToken() async {
    final auth = context.read<AuthProvider>();

    final cached = auth.reauthToken;

    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _XcaPasswordDialog();
      },
    );

    if (!mounted || password == null || password.trim().isEmpty) {
      return null;
    }

    try {
      final result = await _service!.reauthenticatePassword(password: password);

      if (!mounted) {
        return result.token;
      }

      auth.saveReauthToken(
        token: result.token,
        expiresInSeconds: result.expiresInSeconds,
      );

      return result.token;
    } on XcaReportException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }

      return null;
    }
  }

  // ============================================================
  // STEP 4. XCA 최종 확정
  // ============================================================

  Future<void> _finalizeReport() async {
    if (_isBusy || _isSigned) {
      return;
    }

    var digest = _contentSha256?.trim().toLowerCase();

    if (digest == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      final refreshed = await _reloadPdf();

      if (!mounted || refreshed == null) {
        return;
      }

      digest = refreshed.contentSha256?.trim().toLowerCase();

      if (digest == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
        _showMessage(
          'Draft PDF의 보고서 무결성 해시를 '
          '확인할 수 없습니다. 서버 PDF 응답을 확인해주세요.',
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('XCA 보고서를 최종 확정할까요?'),
          content: const Text(
            '선택한 영상, 보고서 본문, AI 참고 분석의 '
            '제한사항을 모두 검토한 뒤 진행해주세요.\n\n'
            '최종 확정하면 의료진 승인 기록과 FINAL 서명이 '
            '생성되고 Signed PDF가 보존됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('검토 완료 · 최종 확정'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final reauthToken = await _resolveReauthToken();

    if (!mounted || reauthToken == null) {
      return;
    }

    setState(() {
      _isFinalizing = true;
    });

    try {
      await _service!.finalizeXcaReport(
        versionId: widget.versionId,
        patientId: widget.patientId,
        medicalResultId: widget.medicalResultId,
        contentSha256: digest,
        reauthToken: reauthToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSigned = true;
      });

      _showMessage('XCA 보고서 최종 확정 및 서명이 완료되었습니다.');

      await _reloadPdf(showError: true);
    } on XcaReportUnauthorizedException catch (error) {
      if (!mounted) {
        return;
      }

      context.read<AuthProvider>().clearReauthToken();

      _showMessage('${error.message} 다시 재인증 후 시도해주세요.');
    } on XcaReportConflictException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('${error.message} 최신 PDF를 다시 확인해주세요.');

      await _reloadPdf(showError: false);
    } on XcaReportUncertainException catch (error) {
      if (!mounted) {
        return;
      }

      // Backend 계약상 503은 DB commit 결과가 불확실할 수 있다.
      // 동일 서명을 바로 재시도하지 않고 최신 PDF부터 확인한다.
      _showMessage(error.message);

      final document = await _reloadPdf(showError: false);

      if (!mounted) {
        return;
      }

      if (document?.isSigned == true) {
        setState(() {
          _isSigned = true;
        });

        _showMessage('서명된 PDF가 확인되었습니다.');
      }
    } on XcaReportException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFinalizing = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 5. 환자 공개
  // ============================================================

  Future<void> _releaseReport() async {
    if (_isBusy || !_isSigned || _isReleased) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('환자에게 결과를 공개할까요?'),
          content: const Text(
            '최종 서명된 XCA 보고서가 환자 공개 상태로 '
            '전환됩니다.\n\n'
            'Backend 정책상 최종 서명한 의사와 동일한 '
            '의사만 공개할 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('환자에게 공개'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final reauthToken = await _resolveReauthToken();

    if (!mounted || reauthToken == null) {
      return;
    }

    setState(() {
      _isReleasing = true;
    });

    try {
      await _service!.releaseXcaReport(
        versionId: widget.versionId,
        patientId: widget.patientId,
        medicalResultId: widget.medicalResultId,
        reauthToken: reauthToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isReleased = true;
      });

      _showMessage('환자 공개가 완료되었습니다.');
    } on XcaReportUnauthorizedException catch (error) {
      if (!mounted) {
        return;
      }

      context.read<AuthProvider>().clearReauthToken();

      _showMessage('${error.message} 다시 재인증 후 시도해주세요.');
    } on XcaReportException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReleasing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // STEP 6. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statusLabel = _isReleased
        ? '환자 공개 완료'
        : _isSigned
        ? 'Signed'
        : 'Draft';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2D XCA 보고서 미리보기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '$statusLabel v${widget.versionNo} · '
              'Version #${widget.versionId}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(context),
          Expanded(
            child: PdfPreview(
              build: (_) async => _pdfBytes,
              pdfFileName: _isSigned
                  ? 'xca-signed-v${widget.versionNo}.pdf'
                  : 'xca-draft-v${widget.versionNo}.pdf',
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              useActions: false,
              onError: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 32,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'PDF를 표시하지 못했습니다.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final icon = _isReleased
        ? Icons.visibility_outlined
        : _isSigned
        ? Icons.verified_outlined
        : Icons.info_outline_rounded;

    final message = _isReleased
        ? '최종 서명된 XCA 보고서가 환자에게 공개되었습니다.'
        : _isSigned
        ? '의료진 최종 확정 및 서명이 완료된 Signed PDF입니다.'
        : '현재 문서는 의료진 검토용 Draft PDF입니다. '
              '내용을 확인한 뒤 최종 확정을 진행해주세요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Patient #${widget.patientId}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _isReleased
                    ? '공개 완료'
                    : _isSigned
                    ? 'Signed PDF 확인 완료 후 환자 공개를 진행할 수 있습니다.'
                    : _contentSha256 == null
                    ? '보고서 무결성 정보 확인이 필요합니다.'
                    : 'Draft PDF 내용을 모두 확인한 뒤 최종 확정해주세요.',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(width: 16),

            if (!_isSigned)
              FilledButton.icon(
                onPressed: _isBusy ? null : _finalizeReport,
                icon: _isFinalizing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: Text(_isFinalizing ? '최종 확정 중...' : '최종 확정 및 서명'),
              )
            else if (!_isReleased)
              FilledButton.icon(
                onPressed: _isBusy ? null : _releaseReport,
                icon: _isReleasing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_outlined, size: 18),
                label: Text(_isReleasing ? '공개 처리 중...' : '환자에게 공개'),
              )
            else
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('환자 공개 완료'),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Password Reauthentication Dialog
// ============================================================

class _XcaPasswordDialog extends StatefulWidget {
  const _XcaPasswordDialog();

  @override
  State<_XcaPasswordDialog> createState() => _XcaPasswordDialogState();
}

class _XcaPasswordDialogState extends State<_XcaPasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;

    if (value.isEmpty) {
      setState(() {
        _error = '비밀번호를 입력해주세요.';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('의료진 재인증'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보고서 최종 확정 및 환자 공개는 '
              '민감 작업이므로 현재 의료진 계정의 '
              '재인증이 필요합니다.',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '비밀번호',
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
              onSubmitted: (_) {
                _submit();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '재인증 토큰은 유효 시간 동안 재사용됩니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('재인증')),
      ],
    );
  }
}
