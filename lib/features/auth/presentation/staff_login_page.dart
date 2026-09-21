import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/security/biometric_auth_service.dart';

// ============================================================
// STEP 1. Staff Login Page
// 의료진 전용 로그인 화면
// ============================================================

class StaffLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const StaffLoginPage({super.key, this.onLoginSuccess});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();

  late final AnimationController _animationController;

  bool _loading = false;
  bool _obscurePassword = true;

  String? _error;

  // ============================================================
  // Biometric Login
  // ============================================================

  static const String _biometricLoginKey = 'settings_biometric_login';

  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _biometricLoginAvailable = false;
  bool _biometricLoading = false;

  // ============================================================
  // STEP 2. Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkBiometricLoginAvailability());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3-1. Biometric Login Availability
  // ============================================================

  Future<void> _checkBiometricLoginAvailability() async {
    final preferences = await SharedPreferences.getInstance();

    final biometricEnabled = preferences.getBool(_biometricLoginKey) ?? false;

    if (!biometricEnabled || !mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();

    // ==========================================================
    // 현재 구조에서는 Refresh Token이 자동 로그인 설정과 함께 저장됨
    // ==========================================================

    final autoLoginEnabled = await auth.authStorage.isAutoLoginEnabled();

    final storedRefreshToken = await auth.authStorage.readRefreshToken();

    final biometricAvailable = await _biometricAuthService.isAvailable();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricLoginAvailable =
          biometricEnabled &&
          autoLoginEnabled &&
          storedRefreshToken != null &&
          storedRefreshToken.isNotEmpty &&
          biometricAvailable;
    });

    debugPrint('[BIOMETRIC LOGIN] available=$_biometricLoginAvailable');
  }

  // ============================================================
  // STEP 3-2. Biometric Login
  // ============================================================

  Future<void> _handleBiometricLogin() async {
    if (_biometricLoading || !_biometricLoginAvailable) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _biometricLoading = true;
      _error = null;
    });

    try {
      // ========================================================
      // 1. 기기 생체 인증
      // ========================================================

      final authenticated = await _biometricAuthService.authenticate(
        reason: 'DUGN 의료진 로그인을 인증해주세요.',
      );

      if (!mounted) {
        return;
      }

      if (!authenticated) {
        setState(() {
          _error = '생체 인증이 완료되지 않았습니다.';
        });

        return;
      }

      // ========================================================
      // 2. 저장된 Refresh Token으로 세션 복원
      // ========================================================

      final auth = context.read<AuthProvider>();

      final restored = await auth.restoreSession();

      if (!mounted) {
        return;
      }

      if (!restored) {
        setState(() {
          _biometricLoginAvailable = false;
          _error =
              '저장된 로그인 세션이 만료되었습니다. '
              '아이디와 비밀번호로 다시 로그인해주세요.';
        });

        return;
      }

      debugPrint('[BIOMETRIC LOGIN] 의료진 생체 로그인 성공');

      // ========================================================
      // 3. 기존 로그인 성공 흐름 그대로 사용
      // ========================================================

      widget.onLoginSuccess?.call();
    } catch (error) {
      debugPrint('[BIOMETRIC LOGIN] 로그인 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _error = '생체 로그인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _biometricLoading = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 3. Login
  // 기존 AuthProvider.login() 사용
  // ============================================================

  Future<void> _handleLogin() async {
    if (_loading) {
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final success = await auth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        setState(() {
          _error = '아이디 또는 비밀번호를 확인해주세요.';
        });

        return;
      }

      widget.onLoginSuccess?.call();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
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
  // STEP 4. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          if (compact) {
            return Container(
              color: colorScheme.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildLoginPanel(),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(flex: 11, child: _buildVisualPanel()),
              Expanded(flex: 9, child: _buildLoginPanel()),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 5. Left Visual Panel
  // React login-visual 대응
  // ============================================================

  Widget _buildVisualPanel() {
    const background = Color(0xFF071C2D);

    const panel = Color(0xFF0C2A43);

    const primaryBlue = Color(0xFF4F8CFF);

    const beatRed = Color(0xFFE43D42);

    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(48, 40, 48, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // Brand
          // ====================================================
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: beatRed,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DUGN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'DUGN CLINICAL AI WORKSPACE',
                    style: TextStyle(
                      color: Color(0xFF89A7BC),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // ====================================================
          // Main Copy
          // ====================================================
          const Text(
            'DUGN CLINICAL WORKSPACE',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            '영상부터 판독까지,\n하나의 흐름으로',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            '환자 정보와 CAG·AI 분석 결과를 한 화면에서 검토하고\n'
            '더 빠르고 정확하게 판독을 완료하세요.',
            style: TextStyle(
              color: Color(0xFFAFC2D1),
              fontSize: 13,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 24),

          // ====================================================
          // Animated Clinical Graphic
          // ====================================================
          Expanded(
            flex: 4,
            child: Center(
              child: SizedBox(
                width: 320,
                height: 320,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _AngioMotionPainter(
                        progress: _animationController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ====================================================
          // Server Status
          // ====================================================
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF55E0C1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'API 서버 연결 준비됨',
                style: TextStyle(
                  color: Color(0xFF91A9BA),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 6. Right Login Panel
  // React login-form-panel 대응
  // ============================================================

  Widget _buildLoginPanel() {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 36),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // Header
                // ==================================================
                Text(
                  '의료진 전용',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '로그인',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'CDSS 의료진 계정으로 로그인해주세요.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 34),

                // ==================================================
                // Username
                // ==================================================
                const _FieldLabel(text: '아이디'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _usernameController,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    hintText: '아이디를 입력하세요',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아이디를 입력해주세요.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // Password
                // ==================================================
                const _FieldLabel(text: '비밀번호'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력하세요',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // Error
                // ==================================================
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ==================================================
                // Login Button
                // ==================================================
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _loading ? null : _handleLogin,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                if (_biometricLoginAvailable) ...[
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _biometricLoading
                          ? null
                          : _handleBiometricLogin,
                      icon: _biometricLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint_rounded, size: 22),
                      label: Text(
                        _biometricLoading ? '인증 중...' : '생체 인증으로 로그인',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ==================================================
                // Security Notice
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '환자 개인정보 보호를 위해 공용 기기에서는 '
                        '사용 후 반드시 로그아웃하세요.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Field Label
// ============================================================

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

// ============================================================
// STEP 8. AngioCAD Motion Painter
// React SVG 디자인에 가깝게 재구성
// ============================================================

class _AngioMotionPainter extends CustomPainter {
  final double progress;

  const _AngioMotionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 360;
    final scaleY = size.height / 360;

    Offset point(double x, double y) {
      return Offset(x * scaleX, y * scaleY);
    }

    final center = point(180, 180);

    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;

    // ==========================================================
    // 1. Outer / Inner Orbit
    // ==========================================================

    final outerOrbitPaint = Paint()
      ..color = const Color(0xFF4F8CFF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final innerOrbitPaint = Paint()
      ..color = const Color(0xFF55E0C1).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 145 * scaleX, outerOrbitPaint);

    canvas.drawCircle(center, 105 * scaleX, innerOrbitPaint);

    // ==========================================================
    // 2. Scan Rings
    // ==========================================================

    final scanRingPaint1 = Paint()
      ..color = const Color(0xFF55E0C1).withValues(alpha: 0.10 + pulse * 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final scanRingPaint2 = Paint()
      ..color = const Color(
        0xFF82C7FF,
      ).withValues(alpha: 0.08 + (1 - pulse) * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, (66 + pulse * 12) * scaleX, scanRingPaint1);

    canvas.drawCircle(center, (78 + pulse * 8) * scaleX, scanRingPaint2);

    // ==========================================================
    // 3. Coronary Vessel Paths
    // React SVG의 motion-vessels 형태
    // ==========================================================

    final vesselPaint = Paint()
      ..color = const Color(0xFF69A9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final branchPaint = Paint()
      ..color = const Color(0xFF55E0C1).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Main vessel
    final mainVessel = Path()
      ..moveTo(point(180, 276).dx, point(180, 276).dy)
      ..cubicTo(
        point(178, 244).dx,
        point(178, 244).dy,
        point(179, 219).dx,
        point(179, 219).dy,
        point(182, 192).dx,
        point(182, 192).dy,
      )
      ..cubicTo(
        point(185, 165).dx,
        point(185, 165).dy,
        point(183, 137).dx,
        point(183, 137).dy,
        point(174, 105).dx,
        point(174, 105).dy,
      )
      ..cubicTo(
        point(169, 87).dx,
        point(169, 87).dy,
        point(161, 70).dx,
        point(161, 70).dy,
        point(151, 54).dx,
        point(151, 54).dy,
      );

    // Left branch
    final leftVessel = Path()
      ..moveTo(point(181, 195).dx, point(181, 195).dy)
      ..cubicTo(
        point(157, 177).dx,
        point(157, 177).dy,
        point(136, 158).dx,
        point(136, 158).dy,
        point(118, 133).dx,
        point(118, 133).dy,
      )
      ..cubicTo(
        point(102, 111).dx,
        point(102, 111).dy,
        point(92, 88).dx,
        point(92, 88).dy,
        point(86, 67).dx,
        point(86, 67).dy,
      );

    // Right branch
    final rightVessel = Path()
      ..moveTo(point(182, 190).dx, point(182, 190).dy)
      ..cubicTo(
        point(205, 168).dx,
        point(205, 168).dy,
        point(229, 151).dx,
        point(229, 151).dy,
        point(256, 139).dx,
        point(256, 139).dy,
      )
      ..cubicTo(
        point(276, 130).dx,
        point(276, 130).dy,
        point(294, 126).dx,
        point(294, 126).dy,
        point(312, 126).dx,
        point(312, 126).dy,
      );

    // Lower branch
    final lowerVessel = Path()
      ..moveTo(point(180, 220).dx, point(180, 220).dy)
      ..cubicTo(
        point(202, 224).dx,
        point(202, 224).dy,
        point(224, 238).dx,
        point(224, 238).dy,
        point(244, 260).dx,
        point(244, 260).dy,
      )
      ..cubicTo(
        point(256, 273).dx,
        point(256, 273).dy,
        point(267, 288).dx,
        point(267, 288).dy,
        point(276, 305).dx,
        point(276, 305).dy,
      );

    canvas.drawPath(mainVessel, vesselPaint);

    canvas.drawPath(leftVessel, branchPaint);

    canvas.drawPath(rightVessel, vesselPaint);

    canvas.drawPath(lowerVessel, vesselPaint);

    // ==========================================================
    // 4. ECG Track
    // ==========================================================

    final heartbeatPath = Path()
      ..moveTo(point(44, 181).dx, point(44, 181).dy)
      ..lineTo(point(113, 181).dx, point(113, 181).dy)
      ..lineTo(point(130, 181).dx, point(130, 181).dy)
      ..lineTo(point(143, 160).dx, point(143, 160).dy)
      ..lineTo(point(159, 214).dx, point(159, 214).dy)
      ..lineTo(point(176, 131).dx, point(176, 131).dy)
      ..lineTo(point(196, 197).dx, point(196, 197).dy)
      ..lineTo(point(210, 181).dx, point(210, 181).dy)
      ..lineTo(point(316, 181).dx, point(316, 181).dy);

    final heartbeatTrackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(heartbeatPath, heartbeatTrackPaint);

    final heartbeatPaint = Paint()
      ..color = const Color(0xFFE43D42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ==========================================================
    // ECG 선이 반복적으로 지나가는 효과
    // ==========================================================

    for (final metric in heartbeatPath.computeMetrics()) {
      final length = metric.length;

      final visibleLength = length * 0.42;

      final start = length * ((progress * 1.3) % 1);

      final end = start + visibleLength;

      if (end <= length) {
        canvas.drawPath(metric.extractPath(start, end), heartbeatPaint);
      } else {
        canvas.drawPath(metric.extractPath(start, length), heartbeatPaint);

        canvas.drawPath(metric.extractPath(0, end - length), heartbeatPaint);
      }
    }

    // ==========================================================
    // 5. Core Glow
    // ==========================================================

    final glowPaint = Paint()
      ..color = const Color(0xFF82C7FF).withValues(alpha: 0.14 + pulse * 0.18);

    canvas.drawCircle(point(180, 181), (18 + pulse * 5) * scaleX, glowPaint);

    final corePaint = Paint()..color = const Color(0xFFE43D42);

    canvas.drawCircle(point(180, 181), 7 * scaleX, corePaint);
  }

  @override
  bool shouldRepaint(covariant _AngioMotionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
