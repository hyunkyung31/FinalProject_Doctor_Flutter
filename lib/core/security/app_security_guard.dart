import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'biometric_auth_service.dart';

import '../auth/auth_provider.dart';

// ============================================================
// STEP 1. Application Security Guard
//
// 병원 보안 정책
// - 15분 미사용 시 자동 잠금
// - 백그라운드 전환 시 화면 보호 항상 적용
// - 잠금 해제 시 현재 의료진 계정 재인증
// ============================================================

class AppSecurityGuard extends StatefulWidget {
  final Widget child;

  const AppSecurityGuard({super.key, required this.child});

  @override
  State<AppSecurityGuard> createState() => _AppSecurityGuardState();
}

class _AppSecurityGuardState extends State<AppSecurityGuard>
    with WidgetsBindingObserver {
  // ============================================================
  // STEP 2. Security Policy
  // ============================================================

  static const Duration _autoLockDuration = Duration(minutes: 15);

  // ============================================================
  // STEP 3. Biometric
  // ============================================================

  static const String _biometricLoginKey = 'settings_biometric_login';

  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _biometricEnabled = false;
  bool _biometricAuthenticating = false;

  // ============================================================
  // App Resume Reauthentication
  // ============================================================

  static const String _reauthenticationKey = 'settings_reauthentication';

  bool _reauthenticationEnabled = true;

  // 실제로 앱이 background까지 갔는지 구분
  bool _wasInBackground = false;

  // ============================================================
  // STEP 3. State
  // ============================================================

  Timer? _lockTimer;

  DateTime _lastActivity = DateTime.now();

  bool _locked = false;
  bool _backgroundProtected = false;
  bool _wasAuthenticated = false;

  bool _loading = false;
  bool _obscurePassword = true;

  String? _unlockError;

  final TextEditingController _passwordController = TextEditingController();

  // ============================================================
  // STEP 4. Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(_loadBiometricSetting());

    unawaited(_loadReauthenticationSetting());
  }
  // ============================================================
  // STEP 4-1. Biometric Setting
  // ============================================================

  Future<void> _loadBiometricSetting() async {
    final preferences = await SharedPreferences.getInstance();

    final enabled = preferences.getBool(_biometricLoginKey) ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricEnabled = enabled;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _lockTimer?.cancel();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 4-2. Reauthentication Setting
  // ============================================================

  Future<void> _loadReauthenticationSetting() async {
    final preferences = await SharedPreferences.getInstance();

    final enabled = preferences.getBool(_reauthenticationKey) ?? true;

    if (!mounted) {
      return;
    }

    setState(() {
      _reauthenticationEnabled = enabled;
    });
  }

  // ============================================================
  // STEP 5. User Activity
  // ============================================================

  void _registerActivity() {
    if (_locked || _backgroundProtected) {
      return;
    }

    _lastActivity = DateTime.now();

    _scheduleAutoLock();
  }

  // ============================================================
  // STEP 6. Auto Lock Timer
  // ============================================================

  void _scheduleAutoLock() {
    _lockTimer?.cancel();

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated || _locked) {
      return;
    }

    final elapsed = DateTime.now().difference(_lastActivity);

    final remaining = _autoLockDuration - elapsed;

    if (remaining <= Duration.zero) {
      _lockApp();
      return;
    }

    _lockTimer = Timer(remaining, _lockApp);

    debugPrint(
      '[SECURITY] 자동 잠금 예약: '
      '${remaining.inSeconds}초 후',
    );
  }

  // ============================================================
  // STEP 7. Lock
  // ============================================================

  void _lockApp() {
    if (!mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated || _locked) {
      return;
    }

    _lockTimer?.cancel();

    unawaited(_loadBiometricSetting());

    debugPrint('[SECURITY] 자동 잠금 실행');

    setState(() {
      _locked = true;
      _unlockError = null;
      _passwordController.clear();
    });
  }

  // ============================================================
  // STEP 8. App Lifecycle
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_handleAppResumed());
        break;

      case AppLifecycleState.inactive:
        _handleAppBackground(markForReauthentication: false);
        break;

      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _handleAppBackground(markForReauthentication: true);
        break;

      case AppLifecycleState.detached:
        _lockTimer?.cancel();
        break;
    }
  }

  // ============================================================
  // STEP 9. Background Protection
  // ============================================================

  void _handleAppBackground({required bool markForReauthentication}) {
    // ==========================================================
    // 생체인증 시스템 화면은 background 전환으로 간주하지 않음
    // ==========================================================

    if (_biometricAuthenticating) {
      return;
    }

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated || !mounted) {
      return;
    }

    // ==========================================================
    // paused / hidden일 때만 실제 background 진입으로 기록
    // ==========================================================

    if (markForReauthentication) {
      _wasInBackground = true;

      debugPrint('[SECURITY] 실제 백그라운드 진입');
    }

    // ==========================================================
    // 의료정보 화면 보호
    // ==========================================================

    if (!_backgroundProtected) {
      debugPrint('[SECURITY] 백그라운드 화면 보호 적용');

      setState(() {
        _backgroundProtected = true;
      });
    }
  }

  // ============================================================
  // STEP 10. Resume
  // ============================================================

  Future<void> _handleAppResumed() async {
    if (!mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();

    if (!auth.isAuthenticated) {
      _wasInBackground = false;
      return;
    }

    debugPrint('[SECURITY] 앱 복귀');

    // ==========================================================
    // 보호 화면 해제
    // ==========================================================

    if (_backgroundProtected) {
      setState(() {
        _backgroundProtected = false;
      });
    }

    // ==========================================================
    // 생체인증 자체로 발생한 lifecycle 변화라면 무시
    // ==========================================================

    if (_biometricAuthenticating) {
      return;
    }

    // ==========================================================
    // 설정 화면에서 변경했을 수 있으므로 최신 값 다시 확인
    // ==========================================================

    await _loadReauthenticationSetting();

    if (!mounted) {
      return;
    }

    // 이미 잠겨 있다면 그대로 유지
    if (_locked) {
      _wasInBackground = false;
      return;
    }

    final elapsed = DateTime.now().difference(_lastActivity);

    // ==========================================================
    // 15분 이상 경과 → 자동 잠금
    // ==========================================================

    if (elapsed >= _autoLockDuration) {
      _wasInBackground = false;

      _lockApp();

      return;
    }

    // ==========================================================
    // 실제 background에서 복귀했고
    // 앱 복귀 시 재인증 설정이 ON → 즉시 잠금
    // ==========================================================

    if (_wasInBackground && _reauthenticationEnabled) {
      _wasInBackground = false;

      debugPrint('[SECURITY] 앱 복귀 재인증 요청');

      _lockApp();

      return;
    }

    _wasInBackground = false;

    _scheduleAutoLock();
  }

  // ============================================================
  // STEP 11. Unlock
  // 현재 로그인 계정으로 재인증
  // ============================================================

  Future<void> _unlock() async {
    if (_loading) {
      return;
    }

    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _unlockError = '비밀번호를 입력해주세요.';
      });

      return;
    }

    final auth = context.read<AuthProvider>();

    final username = auth.currentUser?.username.trim() ?? '';

    if (username.isEmpty) {
      setState(() {
        _unlockError = '현재 로그인 계정을 확인할 수 없습니다.';
      });

      return;
    }

    setState(() {
      _loading = true;
      _unlockError = null;
    });

    try {
      final success = await auth.login(username: username, password: password);

      if (!mounted) {
        return;
      }

      if (!success) {
        setState(() {
          _unlockError = '비밀번호를 확인해주세요.';
        });

        return;
      }

      _passwordController.clear();

      _lastActivity = DateTime.now();

      setState(() {
        _locked = false;
        _unlockError = null;
      });

      _scheduleAutoLock();

      debugPrint('[SECURITY] 잠금 해제 성공');
    } catch (error) {
      debugPrint('[SECURITY] 잠금 해제 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _unlockError = '인증 중 오류가 발생했습니다.';
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
  // STEP 12. Biometric Unlock
  // ============================================================

  Future<void> _unlockWithBiometric() async {
    if (!_biometricEnabled || _biometricAuthenticating || !_locked) {
      return;
    }

    setState(() {
      _biometricAuthenticating = true;
      _unlockError = null;
    });

    try {
      final authenticated = await _biometricAuthService.authenticate(
        reason: 'DUGN 앱 잠금을 해제해주세요.',
      );

      if (!mounted) {
        return;
      }

      if (!authenticated) {
        setState(() {
          _unlockError = '생체 인증이 완료되지 않았습니다.';
        });

        return;
      }

      _lastActivity = DateTime.now();

      setState(() {
        _locked = false;
        _unlockError = null;
      });

      _scheduleAutoLock();

      debugPrint('[SECURITY] 생체인증 잠금 해제 성공');
    } finally {
      if (mounted) {
        setState(() {
          _biometricAuthenticating = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 12. Main
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ==========================================================
    // 로그인 / 로그아웃 상태 변경 감지
    // ==========================================================

    if (auth.isAuthenticated != _wasAuthenticated) {
      _wasAuthenticated = auth.isAuthenticated;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        if (auth.isAuthenticated) {
          _lastActivity = DateTime.now();

          debugPrint(
            '[SECURITY] 병원 보안 정책 적용 '
            '- 자동 잠금 15분 / 화면 보호 항상 사용',
          );

          _scheduleAutoLock();
        } else {
          _lockTimer?.cancel();

          if (_locked || _backgroundProtected) {
            setState(() {
              _locked = false;
              _backgroundProtected = false;
              _wasInBackground = false;
            });
          }
        }
      });
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _registerActivity();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,

          // ====================================================
          // Background Screen Protection
          // ====================================================
          if (_backgroundProtected && auth.isAuthenticated)
            const _BackgroundProtectionScreen(),

          // ====================================================
          // Auto Lock
          // ====================================================
          if (_locked && auth.isAuthenticated)
            _AppLockScreen(
              name: auth.userName,
              department: auth.department,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              loading: _loading,
              biometricEnabled: _biometricEnabled,
              biometricLoading: _biometricAuthenticating,
              error: _unlockError,
              onPasswordVisibilityTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onBiometricUnlock: _unlockWithBiometric,
              onUnlock: _unlock,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Background Protection Screen
// ============================================================

class _BackgroundProtectionScreen extends StatelessWidget {
  const _BackgroundProtectionScreen();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFF071C2D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProtectionIcon(),

            SizedBox(height: 18),

            Text(
              'DUGN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),

            SizedBox(height: 7),

            Text(
              '의료정보 보호를 위해 화면을 가렸습니다.',
              style: TextStyle(color: Color(0xFFAFC2D1), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 14. Protection Icon
// ============================================================

class _ProtectionIcon extends StatelessWidget {
  const _ProtectionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 30),
    );
  }
}

// ============================================================
// STEP 15. Auto Lock Screen
// ============================================================

class _AppLockScreen extends StatelessWidget {
  final String name;
  final String department;

  final TextEditingController passwordController;

  final bool obscurePassword;
  final bool loading;
  final bool biometricEnabled;
  final bool biometricLoading;

  final VoidCallback onBiometricUnlock;

  final String? error;

  final VoidCallback onPasswordVisibilityTap;
  final VoidCallback onUnlock;

  const _AppLockScreen({
    required this.name,
    required this.department,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.biometricEnabled,
    required this.biometricLoading,
    required this.onBiometricUnlock,
    required this.error,
    required this.onPasswordVisibilityTap,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: colorScheme.primary,
                    size: 27,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  '앱이 잠겼습니다',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  '$name · $department',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '계속하려면 현재 계정의 비밀번호를 입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: passwordController,
                  enabled: !loading,
                  obscureText: obscurePassword,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    onUnlock();
                  },
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: loading ? null : onPasswordVisibilityTap,
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),

                if (biometricEnabled) ...[
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: loading || biometricLoading
                          ? null
                          : onBiometricUnlock,
                      icon: biometricLoading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint_rounded, size: 21),
                      label: Text(
                        biometricLoading ? '인증 중...' : '생체 인증으로 잠금 해제',
                      ),
                    ),
                  ),
                ],

                if (error != null) ...[
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error!,
                      style: TextStyle(color: colorScheme.error, fontSize: 11),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: loading ? null : onUnlock,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            '잠금 해제',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
