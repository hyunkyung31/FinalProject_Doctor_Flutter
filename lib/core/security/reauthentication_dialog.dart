import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import 'reauthentication_service.dart';

// ============================================================
// STEP 1. Sensitive Reauthentication
//
// 민감 작업 실행 전 재인증을 보장한다.
//
// - 기존 reauth token이 아직 유효하면 Dialog 생략
// - 만료되었으면 비밀번호 재인증
// - 성공 시 AuthProvider에 5분 reauth token 저장
// ============================================================

Future<bool> ensureSensitiveReauthentication(BuildContext context) async {
  final auth = context.read<AuthProvider>();

  // ==========================================================
  // 이미 유효한 재인증 Token이 있으면 다시 묻지 않음
  // ==========================================================

  if (auth.hasValidReauthToken) {
    debugPrint(
      '[REAUTH] 기존 재인증 세션 사용 '
      '(${auth.reauthRemaining.inSeconds}초 남음)',
    );

    return true;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return const _ReauthenticationDialog();
    },
  );

  return result ?? false;
}

// ============================================================
// STEP 2. Reauthentication Dialog
// ============================================================

class _ReauthenticationDialog extends StatefulWidget {
  const _ReauthenticationDialog();

  @override
  State<_ReauthenticationDialog> createState() =>
      _ReauthenticationDialogState();
}

class _ReauthenticationDialogState extends State<_ReauthenticationDialog> {
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Password Reauthentication
  // ============================================================

  Future<void> _authenticate() async {
    if (_loading) {
      return;
    }

    final password = _passwordController.text;

    if (password.trim().isEmpty) {
      setState(() {
        _error = '비밀번호를 입력해주세요.';
      });

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final service = ReauthenticationService(
        apiClient: auth.authService.apiClient,
      );

      final result = await service.verifyPassword(password: password);

      if (!mounted) {
        return;
      }

      // ========================================================
      // Backend reauth token 저장
      // 현재 Backend 기준 expires_in = 300초
      // ========================================================

      auth.saveReauthToken(
        token: result.reauthToken,
        expiresInSeconds: result.expiresIn,
      );

      debugPrint(
        '[REAUTH] 비밀번호 재인증 성공 '
        '- ${result.expiresIn}초 유효',
      );

      Navigator.of(context).pop(true);
    } on ReauthenticationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
      });
    } catch (error) {
      debugPrint('[REAUTH] 재인증 오류: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _error = '재인증 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),

      // ========================================================
      // Header
      // ========================================================
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              '민감 작업 재인증',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),

      // ========================================================
      // Content
      // ========================================================
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '보안을 위해 현재 로그인한 의료진의 '
              '비밀번호를 다시 입력해주세요.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              enabled: !_loading,
              obscureText: _obscurePassword,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _authenticate();
              },
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: _loading
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
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colorScheme.error,
                    size: 17,
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            Text(
              '인증 후 5분 동안 추가 재인증 없이 '
              '민감 작업을 수행할 수 있습니다.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // Actions
      // ========================================================
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('취소'),
        ),

        FilledButton.icon(
          onPressed: _loading ? null : _authenticate,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_outlined, size: 17),
          label: Text(_loading ? '인증 중...' : '인증'),
        ),
      ],
    );
  }
}
