import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/text_scale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

// ============================================================
// STEP 2. Settings Page
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ============================================================
  // 알림 설정
  // ============================================================

  bool _reservationNotification = true;
  bool _examinationNotification = true;
  bool _aiNotification = true;
  bool _consultationNotification = true;
  bool _scheduleNotification = true;

  // ============================================================
  // 보안 설정
  //
  // 1차 UI 단계에서는 화면 상태만 변경.
  // 실제 자동 로그인 / 생체인증 연결은 추후 진행.
  // ============================================================

  bool _autoLogin = true;
  bool _biometricLogin = false;

  // ============================================================
  // STEP 3. Main UI
  //
  // settings는 Sidebar 하단 별도 메뉴이므로 selectedIndex는
  // 실제 AppShell 구조 확인 후 최종 연결합니다.
  //
  // 현재 AppShell에서 음수 index 사용이 안전하지 않을 수 있으므로
  // 일단 화면 확인 시 기존 설정 route의 selectedIndex 값을 사용하거나,
  // AppShell 코드를 확인한 뒤 정확히 맞춥니다.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '설정',

      // ========================================================
      // IMPORTANT
      // 현재 프로젝트의 Settings용 selectedIndex 값을
      // 확인한 뒤 필요하면 이 값만 변경합니다.
      //
      // CDSS 제거 후 일반 Sidebar:
      // 홈 0 / 환자 1 / 예약 2 / 검사 3 /
      // 영상 4 / AI 5 / 협진 6 / 일정 7
      //
      // 설정은 하단 별도 메뉴이므로 AppShell 구현에 따라
      // 별도 처리될 수 있습니다.
      // ========================================================
      selectedIndex: 7,

      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // 상단 안내
                // =================================================
                const Text(
                  '내 계정과 앱 사용 환경을 설정할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
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
  // STEP 4. 내 계정
  // ============================================================

  Widget _buildAccountSection() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 25,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '김OO 의사',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 4),

              Text(
                '순환기내과',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 2),

              Text(
                '의사',
                style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        OutlinedButton.icon(
          onPressed: () {
            _showMessage('계정 정보 화면은 실제 직원 정보 API 연결 후 구현합니다.');
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          label: const Text('계정 정보', style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 5. 화면 설정
  // ============================================================

  Widget _buildDisplaySection() {
    final textScaleProvider = context.watch<TextScaleProvider>();

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

        const _SettingsRow(
          title: '화면 모드',
          subtitle: '기기의 화면 모드 설정을 따릅니다.',
          trailing: _SettingValue(
            icon: Icons.devices_outlined,
            text: '시스템 설정 사용',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 6. 알림
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
          },
        ),
      ],
    );
  }

  // ============================================================
  // STEP 7. 보안
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
          },
        ),

        const _SettingsDivider(),

        _SettingsSwitchRow(
          title: '생체 인증',
          subtitle: '지원되는 기기에서 생체 인증으로 로그인합니다.',
          value: _biometricLogin,
          onChanged: (value) {
            setState(() {
              _biometricLogin = value;
            });

            if (value) {
              _showMessage('현재는 UI DEMO입니다. 실제 생체 인증은 추후 연결합니다.');
            }
          },
        ),

        const _SettingsDivider(),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      '현재 의료진 계정에서 로그아웃합니다.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: const Text('로그아웃', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 8. 로그아웃 확인 Dialog
  //
  // 실제 Auth logout API / token 삭제는 아직 연결하지 않습니다.
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

    if (result != true) {
      return;
    }

    _showMessage('현재는 UI DEMO입니다. 실제 로그아웃은 AuthService와 연결합니다.');
  }

  // ============================================================
  // STEP 9. SnackBar
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
// STEP 10. 공통 설정 Section Card
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.navy),
                ),

                const SizedBox(width: 9),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

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
// STEP 11. 일반 설정 Row
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
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
// STEP 12. Switch 설정 Row
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
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
// STEP 13. 구분선
// ============================================================

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

// ============================================================
// STEP. 실제 TextScaleProvider 글자 크기 Selector
// ============================================================

class _TextScaleSelector extends StatelessWidget {
  final AppTextScaleMode selected;
  final ValueChanged<AppTextScaleMode> onChanged;

  const _TextScaleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        constraints: const BoxConstraints(minWidth: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 15. 일반 값 표시
// ============================================================

class _SettingValue extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SettingValue({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
