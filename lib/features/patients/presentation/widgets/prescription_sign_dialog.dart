import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/patient_prescription_service.dart';

class PrescriptionSignDialog extends StatefulWidget {
  final PatientPrescriptionService service;
  final int prescriptionId;

  const PrescriptionSignDialog({
    super.key,
    required this.service,
    required this.prescriptionId,
  });

  @override
  State<PrescriptionSignDialog> createState() => _PrescriptionSignDialogState();
}

class _PrescriptionSignDialogState extends State<PrescriptionSignDialog> {
  final _passwordController = TextEditingController();

  late final SignatureController _signatureController;

  bool _isSigning = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _signatureController.dispose();

    super.dispose();
  }

  bool _hasValidSignature() {
    final points = _signatureController.points;

    if (points.isEmpty) {
      return false;
    }

    final movePoints = points
        .where((point) => point.type == PointType.move)
        .toList();

    // 점 하나 또는 너무 짧은 획 방지
    if (movePoints.length < 12) {
      return false;
    }

    var minX = movePoints.first.offset.dx;
    var maxX = movePoints.first.offset.dx;
    var minY = movePoints.first.offset.dy;
    var maxY = movePoints.first.offset.dy;

    double pathLength = 0;

    for (var i = 0; i < movePoints.length; i++) {
      final offset = movePoints[i].offset;

      if (offset.dx < minX) minX = offset.dx;
      if (offset.dx > maxX) maxX = offset.dx;
      if (offset.dy < minY) minY = offset.dy;
      if (offset.dy > maxY) maxY = offset.dy;

      if (i > 0) {
        pathLength += (offset - movePoints[i - 1].offset).distance;
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;

    // 너무 작은 낙서 방지
    if (width < 40 && height < 25) {
      return false;
    }

    // 실제로 어느 정도 펜을 움직였는지 확인
    if (pathLength < 80) {
      return false;
    }

    return true;
  }

  Future<void> _signPrescription() async {
    if (!_hasValidSignature()) {
      setState(() {
        _errorMessage =
            '서명이 너무 짧거나 작습니다. '
            '서명란에 다시 작성해 주세요.';
      });

      return;
    }

    final auth = context.read<AuthProvider>();

    String? reauthToken = auth.reauthToken;

    if (reauthToken == null) {
      final password = _passwordController.text;

      if (password.trim().isEmpty) {
        setState(() {
          _errorMessage = '현재 계정의 비밀번호를 입력해 주세요.';
        });

        return;
      }
    }

    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      final signatureBytes = await _signatureController.toPngBytes();

      if (signatureBytes == null || signatureBytes.isEmpty) {
        throw const FormatException('서명 이미지를 생성하지 못했습니다.');
      }

      if (reauthToken == null) {
        final session = await widget.service.reauthenticateForSignature(
          _passwordController.text,
        );

        auth.saveReauthToken(
          token: session.token,
          expiresInSeconds: session.expiresInSeconds,
        );

        reauthToken = session.token;
      }

      _passwordController.clear();

      await widget.service.signPrescriptionWithSignature(
        prescriptionId: widget.prescriptionId,
        reauthToken: reauthToken,
        signatureBytes: signatureBytes,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('[PrescriptionSignDialog] 처방 서명 실패: $error');

      _passwordController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            '처방 서명에 실패했습니다. '
            '비밀번호와 처방 상태를 확인해 주세요.';

        _isSigning = false;
      });
    }
  }

  void _clearSignature() {
    if (_isSigning) {
      return;
    }

    _signatureController.clear();

    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final hasValidReauth = auth.hasValidReauthToken;

    final remainingSeconds = auth.reauthRemaining.inSeconds;

    final remainingMinutes = remainingSeconds <= 0
        ? 0
        : (remainingSeconds / 60).ceil();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.draw_outlined, size: 20, color: AppColors.navy),
          SizedBox(width: 8),
          Text(
            '처방 전자서명',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '아래 서명란에 직접 서명해 주세요.\n'
                  '본인 확인이 필요한 경우에만 현재 로그인 계정의 '
                  '비밀번호를 다시 입력합니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                '서명',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Signature(
                  controller: _signatureController,
                  height: 220,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 7),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isSigning ? null : _clearSignature,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text(
                    '다시 작성',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              if (hasValidReauth)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remainingMinutes > 0
                              ? '본인 확인 완료 · 약 $remainingMinutes분간 유효'
                              : '본인 확인 완료',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextField(
                  controller: _passwordController,
                  enabled: !_isSigning,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isSigning) {
                      _signPrescription();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '본인 확인 비밀번호',
                    hintText: '현재 로그인 계정 비밀번호',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                      onPressed: _isSigning
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 9),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSigning
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('취소'),
        ),

        FilledButton.icon(
          onPressed: _isSigning ? null : _signPrescription,
          icon: _isSigning
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_outlined, size: 16),
          label: Text(_isSigning ? '서명 중' : '서명 완료'),
        ),
      ],
    );
  }
}
