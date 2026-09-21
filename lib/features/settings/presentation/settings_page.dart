import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/settings/text_scale_provider.dart';
import '../../../../core/settings/theme_mode_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../core/security/biometric_auth_service.dart';

// ============================================================
// STEP 1. Settings Page
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ============================================================
  // STEP 2. SharedPreferences Key
  // ============================================================

  static const String _reservationNotificationKey =
      'settings_reservation_notification';

  static const String _examinationNotificationKey =
      'settings_examination_notification';

  static const String _aiNotificationKey = 'settings_ai_notification';

  static const String _cdssNotificationKey = 'settings_cdss_notification';

  static const String _consultationNotificationKey =
      'settings_consultation_notification';

  static const String _chatNotificationKey = 'settings_chat_notification';

  static const String _scheduleNotificationKey =
      'settings_schedule_notification';

  static const String _autoLoginKey = 'settings_auto_login';

  static const String _biometricLoginKey = 'settings_biometric_login';

  static const String _reauthenticationKey = 'settings_reauthentication';

  // ============================================================
  // STEP 3. 알림 설정
  // ============================================================

  bool _reservationNotification = true;

  bool _examinationNotification = true;

  bool _aiNotification = true;

  bool _cdssNotification = true;

  bool _consultationNotification = true;

  bool _chatNotification = true;

  bool _scheduleNotification = true;

  // ============================================================
  // STEP 4. 보안 설정
  // ============================================================

  bool _autoLogin = true;

  bool _biometricLogin = false;

  bool _reauthentication = true;

  // ============================================================
  // STEP 5. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================
  // STEP 6. 저장된 설정 불러오기
  // ============================================================

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _reservationNotification =
          preferences.getBool(_reservationNotificationKey) ?? true;

      _examinationNotification =
          preferences.getBool(_examinationNotificationKey) ?? true;

      _aiNotification = preferences.getBool(_aiNotificationKey) ?? true;

      _cdssNotification = preferences.getBool(_cdssNotificationKey) ?? true;

      _consultationNotification =
          preferences.getBool(_consultationNotificationKey) ?? true;

      _chatNotification = preferences.getBool(_chatNotificationKey) ?? true;

      _scheduleNotification =
          preferences.getBool(_scheduleNotificationKey) ?? true;

      _autoLogin = preferences.getBool(_autoLoginKey) ?? true;

      _biometricLogin = preferences.getBool(_biometricLoginKey) ?? false;

      _reauthentication = preferences.getBool(_reauthenticationKey) ?? true;
    });
  }

  // ============================================================
  // STEP 7. Bool 설정 저장
  // ============================================================

  Future<void> _saveBoolSetting(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(key, value);
  }

  // ============================================================
  // STEP 9. Main UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      pageTitle: '설정',
      selectedIndex: -1,
      body: Material(
        color: theme.scaffoldBackgroundColor,
        child: Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 계정과 앱 사용 환경을 설정할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // 1. 내 계정
                // =================================================
                _SettingsSectionCard(
                  title: '내 계정',
                  icon: Icons.person_outline_rounded,
                  child: _buildAccountSection(),
                ),

                const SizedBox(height: 12),

                // =================================================
                // 2. 화면 설정
                // =================================================
                _SettingsSectionCard(
                  title: '화면 설정',
                  icon: Icons.display_settings_outlined,
                  child: _buildDisplaySection(),
                ),

                const SizedBox(height: 12),

                // =================================================
                // 3. 알림
                // =================================================
                _SettingsSectionCard(
                  title: '알림',
                  icon: Icons.notifications_none_rounded,
                  child: _buildNotificationSection(),
                ),

                const SizedBox(height: 12),

                // =================================================
                // 4. 보안
                // =================================================
                _SettingsSectionCard(
                  title: '보안',
                  icon: Icons.shield_outlined,
                  child: _buildSecuritySection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 10. 내 계정
  // ============================================================

  Widget _buildAccountSection() {
    final theme = Theme.of(context);

    final auth = context.watch<AuthProvider>();

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 25,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${auth.userName} ${auth.displayPosition}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    auth.department,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    auth.displayPosition,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton.icon(
              onPressed: () {
                context.go(AppRoutes.profile);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('계정 정보', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),

        const _SettingsDivider(),

        _SettingsRow(
          title: '로그아웃',
          subtitle: '현재 의료진 계정에서 로그아웃합니다.',
          trailing: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text('로그아웃', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 11. 화면 설정
  // ============================================================

  Widget _buildDisplaySection() {
    final textScaleProvider = context.watch<TextScaleProvider>();

    final themeModeProvider = context.watch<ThemeModeProvider>();

    return Column(
      children: [
        _SettingsRow(
          title: '글자 크기',
          subtitle: '앱 화면의 기본 글자 크기를 조절합니다.',
          trailing: _TextScaleSelector(
            selected: textScaleProvider.mode,
            onChanged: (mode) async {
              await context.read<TextScaleProvider>().setMode(mode);
            },
          ),
        ),

        const _SettingsDivider(),

        _SettingsRow(
          title: '화면 모드',
          subtitle: '시스템 설정 또는 라이트·다크 모드를 선택합니다.',
          trailing: _ThemeModeSelector(
            selected: themeModeProvider.mode,
            onChanged: (mode) async {
              await context.read<ThemeModeProvider>().setMode(mode);
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 12. 알림 설정
  // ============================================================

  Widget _buildNotificationSection() {
    return Column(
      children: [
        _SettingsSwitchRow(
          title: '예약 알림',
          subtitle: '예약 접수 및 변경 사항을 알려드립니다.',
          value: _reservationNotification,
          onChanged: (value) {
            setState(() {
              _reservationNotification = value;
            });

            _saveBoolSetting(_reservationNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '검사 결과 알림',
          subtitle: '검사 결과 등록 및 확정 시 알림을 받습니다.',
          value: _examinationNotification,
          onChanged: (value) {
            setState(() {
              _examinationNotification = value;
            });

            _saveBoolSetting(_examinationNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: 'AI 분석 완료 알림',
          subtitle: '요청한 AI 분석 작업이 완료되면 알려드립니다.',
          value: _aiNotification,
          onChanged: (value) {
            setState(() {
              _aiNotification = value;
            });

            _saveBoolSetting(_aiNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: 'CDSS 검토 알림',
          subtitle: 'CDSS 분석 또는 검토가 필요한 경우 알려드립니다.',
          value: _cdssNotification,
          onChanged: (value) {
            setState(() {
              _cdssNotification = value;
            });

            _saveBoolSetting(_cdssNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '협진 요청 · 의견 알림',
          subtitle: '협진 요청 및 새로운 의견 등록 시 알림을 받습니다.',
          value: _consultationNotification,
          onChanged: (value) {
            setState(() {
              _consultationNotification = value;
            });

            _saveBoolSetting(_consultationNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '채팅 알림',
          subtitle: '새로운 1:1·그룹·협진 채팅 메시지를 알려드립니다.',
          value: _chatNotification,
          onChanged: (value) {
            setState(() {
              _chatNotification = value;
            });

            _saveBoolSetting(_chatNotificationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '일정 · 당직 알림',
          subtitle: '개인 일정과 당직 관련 변경 사항을 알려드립니다.',
          value: _scheduleNotification,
          onChanged: (value) {
            setState(() {
              _scheduleNotification = value;
            });

            _saveBoolSetting(_scheduleNotificationKey, value);
          },
        ),
      ],
    );
  }

  // ============================================================
  // STEP 13. 보안 설정
  // ============================================================

  Widget _buildSecuritySection() {
    return Column(
      children: [
        _SettingsSwitchRow(
          title: '자동 로그인',
          subtitle: '다음 실행 시 로그인 상태를 유지합니다.',
          value: _autoLogin,
          onChanged: (value) {
            setState(() {
              _autoLogin = value;
            });

            _saveBoolSetting(_autoLoginKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsRow(
          title: '자동 잠금',
          subtitle: '15분 동안 사용하지 않으면 앱이 자동으로 잠깁니다.',
          trailing: const _PolicyBadge(label: '15분'),
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '생체 인증',
          subtitle: '앱 잠금 해제와 재인증에 생체 인증을 사용합니다.',
          value: _biometricLogin,
          onChanged: (value) async {
            // ==========================================================
            // 생체인증 OFF
            // ==========================================================

            if (!value) {
              setState(() {
                _biometricLogin = false;
              });

              await _saveBoolSetting(_biometricLoginKey, false);

              if (!mounted) {
                return;
              }

              _showMessage('생체 인증이 비활성화되었습니다.');

              return;
            }

            // ==========================================================
            // 생체인증 ON
            // 먼저 실제 기기 인증 성공 필요
            // ==========================================================

            final biometricService = BiometricAuthService();

            final available = await biometricService.isAvailable();

            if (!mounted) {
              return;
            }

            if (!available) {
              _showMessage('이 기기에 등록된 생체 인증 정보가 없습니다.');

              return;
            }

            final authenticated = await biometricService.authenticate(
              reason: 'DUGN 생체 인증 사용을 활성화해주세요.',
            );

            if (!mounted) {
              return;
            }

            if (!authenticated) {
              _showMessage('생체 인증이 완료되지 않았습니다.');

              return;
            }

            setState(() {
              _biometricLogin = true;
            });

            await _saveBoolSetting(_biometricLoginKey, true);

            if (!mounted) {
              return;
            }

            _showMessage('생체 인증이 활성화되었습니다.');
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '앱 복귀 시 재인증',
          subtitle: '백그라운드에서 앱으로 복귀할 때 다시 인증합니다.',
          value: _reauthentication,
          onChanged: (value) {
            setState(() {
              _reauthentication = value;
            });

            _saveBoolSetting(_reauthenticationKey, value);
          },
        ),

        const _SettingsDivider(),

        _SettingsRow(
          title: '화면 보호',
          subtitle: '백그라운드 전환 시 의료정보 화면을 자동으로 보호합니다.',
          trailing: const _PolicyBadge(label: '항상 사용'),
        ),

        const _SettingsDivider(),

        _SettingsRow(
          title: '화면 캡처 방지',
          subtitle: '환자 의료정보의 화면 캡처와 녹화를 제한합니다.',
          trailing: const _PolicyBadge(label: '항상 사용'),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 14. 로그아웃 확인 Dialog
  // ============================================================

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('현재 계정에서 로그아웃하시겠습니까?'),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) {
      return;
    }

    // ==========================================================
    // 인증 정보 초기화
    // ==========================================================

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // 로그인 화면 이동
    // ==========================================================

    context.go(AppRoutes.login);
  }

  // ============================================================
  // STEP 15. SnackBar
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

// ============================================================
// STEP 16. 공통 설정 Section Card
// ============================================================

class _SettingsSectionCard extends StatelessWidget {
  final String title;

  final IconData icon;

  final Widget child;

  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 9),

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: theme.dividerColor),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 17. 일반 설정 Row
// ============================================================

class _SettingsRow extends StatelessWidget {
  final String title;

  final String subtitle;

  final Widget trailing;

  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          trailing,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 18. Switch 설정 Row
// ============================================================

class _SettingsSwitchRow extends StatelessWidget {
  final String title;

  final String subtitle;

  final bool value;

  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 19. 구분선
// ============================================================

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}

// ============================================================
// STEP 20. Text Scale Selector
// ============================================================

class _TextScaleSelector extends StatelessWidget {
  final AppTextScaleMode selected;

  final ValueChanged<AppTextScaleMode> onChanged;

  const _TextScaleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TextScaleButton(
            label: '시스템',
            selected: selected == AppTextScaleMode.system,
            onTap: () {
              onChanged(AppTextScaleMode.system);
            },
          ),

          _TextScaleButton(
            label: '보통',
            selected: selected == AppTextScaleMode.normal,
            onTap: () {
              onChanged(AppTextScaleMode.normal);
            },
          ),

          _TextScaleButton(
            label: '크게',
            selected: selected == AppTextScaleMode.large,
            onTap: () {
              onChanged(AppTextScaleMode.large);
            },
          ),

          _TextScaleButton(
            label: '아주 크게',
            selected: selected == AppTextScaleMode.extraLarge,
            onTap: () {
              onChanged(AppTextScaleMode.extraLarge);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 21. Text Scale Button
// ============================================================

class _TextScaleButton extends StatelessWidget {
  final String label;

  final bool selected;

  final VoidCallback onTap;

  const _TextScaleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        constraints: const BoxConstraints(minWidth: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 22. Theme Mode Selector
// ============================================================

class _ThemeModeSelector extends StatelessWidget {
  final AppThemeMode selected;

  final ValueChanged<AppThemeMode> onChanged;

  const _ThemeModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeModeButton(
            label: '시스템',
            icon: Icons.devices_outlined,
            selected: selected == AppThemeMode.system,
            onTap: () {
              onChanged(AppThemeMode.system);
            },
          ),

          _ThemeModeButton(
            label: '라이트',
            icon: Icons.light_mode_outlined,
            selected: selected == AppThemeMode.light,
            onTap: () {
              onChanged(AppThemeMode.light);
            },
          ),

          _ThemeModeButton(
            label: '다크',
            icon: Icons.dark_mode_outlined,
            selected: selected == AppThemeMode.dark,
            onTap: () {
              onChanged(AppThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 23. Theme Mode Button
// ============================================================

class _ThemeModeButton extends StatelessWidget {
  final String label;

  final IconData icon;

  final bool selected;

  final VoidCallback onTap;

  const _ThemeModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 24. Security Policy Badge
// ============================================================

class _PolicyBadge extends StatelessWidget {
  final String label;

  const _PolicyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
