import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../auth/access_control.dart';
import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../settings/text_scale_provider.dart';
import '../settings/theme_mode_provider.dart';
import '../../features/chat/presentation/chat_top_bar_button.dart';

// ============================================================
// STEP 1. Navigation Item Model
// ============================================================

class AppNavigationItem {
  final String label;
  final IconData icon;
  final AppPermission permission;

  const AppNavigationItem({
    required this.label,
    required this.icon,
    required this.permission,
  });
}

// ============================================================
// STEP 2. 공통 태블릿 Shell
// 모든 주요 화면에서 Navigation Rail + Top Bar 공유
// ============================================================

class AppShell extends StatelessWidget {
  final Widget body;
  final String pageTitle;
  final int selectedIndex;

  const AppShell({
    super.key,
    required this.body,
    required this.pageTitle,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _SideNavigation(selectedIndex: selectedIndex),

          Expanded(
            child: Column(
              children: [
                _TopBar(pageTitle: pageTitle),

                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 3. Navigation Rail
// ============================================================

class _SideNavigation extends StatelessWidget {
  final int selectedIndex;

  const _SideNavigation({required this.selectedIndex});

  static const List<AppNavigationItem> items = [
    AppNavigationItem(
      label: '홈',
      icon: Icons.home_rounded,
      permission: AppPermission.dashboardView,
    ),

    AppNavigationItem(
      label: '환자',
      icon: Icons.person_outline_rounded,
      permission: AppPermission.patientView,
    ),

    AppNavigationItem(
      label: '예약',
      icon: Icons.calendar_today_outlined,
      permission: AppPermission.appointmentView,
    ),

    AppNavigationItem(
      label: '검사 관리',
      icon: Icons.science_outlined,
      permission: AppPermission.examinationView,
    ),

    AppNavigationItem(
      label: '영상',
      icon: Icons.monitor_heart_outlined,
      permission: AppPermission.imagingView,
    ),

    AppNavigationItem(
      label: 'AI',
      icon: Icons.auto_awesome_outlined,
      permission: AppPermission.aiView,
    ),

    AppNavigationItem(
      label: '협진',
      icon: Icons.groups_outlined,
      permission: AppPermission.consultView,
    ),

    AppNavigationItem(
      label: '일정',
      icon: Icons.event_note_outlined,
      permission: AppPermission.calendarView,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 88,

      // ========================================================
      // 브랜드 Navigation 색상은 라이트 / 다크 공통 유지
      // ========================================================
      color: AppColors.navy,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),

      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // CardioAI Logo
            // ==================================================
            const _AppLogo(),

            const SizedBox(height: 16),

            // ==================================================
            // Navigation Menu
            // ==================================================
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,

                // ========================================================
                // 메뉴 + 설정 버튼
                // ========================================================
                itemCount: items.length + 1,

                separatorBuilder: (_, _) {
                  return const SizedBox(height: 5);
                },

                itemBuilder: (context, index) {
                  // ======================================================
                  // 마지막 항목 = 설정
                  // 일정 바로 아래에 표시
                  // ======================================================

                  if (index == items.length) {
                    return _BottomButton(
                      icon: Icons.settings_outlined,
                      label: '설정',
                      selected:
                          GoRouterState.of(context).uri.path ==
                          AppRoutes.settings,
                      onTap: () {
                        context.go(AppRoutes.settings);
                      },
                    );
                  }

                  final item = items[index];

                  final hasPermission = auth.hasPermission(item.permission);

                  return _NavigationButton(
                    item: item,
                    selected: selectedIndex == index,
                    enabled: hasPermission,
                    onTap: () {
                      _handleNavigation(context, item, hasPermission);
                    },
                  );
                },
              ),
            ),

            // ============================================================
            // Sidebar Footer
            // React 의료진 Web 구조 참고
            // Theme Toggle + Account Profile
            // ============================================================
            const SizedBox(height: 8),

            const Divider(color: Colors.white12, height: 1),

            const SizedBox(height: 10),

            const _ThemeToggleButton(),

            const SizedBox(height: 10),

            const _ProfileButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 4. 메뉴 클릭 처리
  // ============================================================

  void _handleNavigation(
    BuildContext context,
    AppNavigationItem item,
    bool hasPermission,
  ) {
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.label} 화면에 접근할 권한이 없습니다.')),
      );

      return;
    }

    final route = _routeForLabel(item.label);

    if (route == null) {
      return;
    }

    context.go(route);
  }

  // ============================================================
  // Navigation Label → Route
  // ============================================================

  String? _routeForLabel(String label) {
    switch (label) {
      case '홈':
        return AppRoutes.dashboard;

      case '환자':
        return AppRoutes.patients;

      case '예약':
        return AppRoutes.appointments;

      case '검사 관리':
        return AppRoutes.examinations;

      case '영상':
        return AppRoutes.imaging;

      case 'AI':
        return AppRoutes.ai;

      case '협진':
        return AppRoutes.consult;

      case '일정':
        return AppRoutes.calendar;

      default:
        return null;
    }
  }
}

// ============================================================
// STEP 5. App Logo
// ============================================================

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'CardioAI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 6. Navigation Button
// ============================================================

class _NavigationButton extends StatelessWidget {
  final AppNavigationItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = !enabled
        ? Colors.white30
        : selected
        ? Colors.white
        : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 21, color: foregroundColor),

                  if (!enabled)
                    const Positioned(
                      top: -5,
                      right: -7,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                item.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Bottom Navigation Button
// ============================================================

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: selected ? AppColors.navyLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.white54,
                size: 21,
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 8. Top Bar
// ============================================================

class _TopBar extends StatelessWidget {
  final String pageTitle;

  const _TopBar({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final canUseChat = auth.hasPermission(AppPermission.chatView);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),

      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 6,
      ),

      // ========================================================
      // Theme에 따라 라이트 / 다크 자동 적용
      // ========================================================
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),

      child: Row(
        children: [
          // ====================================================
          // 현재 화면 이름
          // ====================================================
          Text(
            pageTitle,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          // ====================================================
          // 날짜
          // ====================================================
          Text(
            _todayText(),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),

          const SizedBox(width: 18),

          // ====================================================
          // 글자 크기 설정
          // ====================================================
          const SizedBox(width: 10),

          const _TextScaleButton(),

          const SizedBox(width: 6),

          // ====================================================
          // Notification
          // ====================================================
          IconButton(
            tooltip: '알림',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('알림 화면은 추후 연결합니다.')));
            },
            icon: Badge(
              label: const Text('5'),
              child: Icon(
                Icons.notifications_none_rounded,
                color: colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 2),

          // ====================================================
          // Chat
          // 실제 unread badge + 우측 Chat Panel
          // ====================================================
          ChatTopBarButton(enabled: canUseChat),

          const SizedBox(width: 14),

          // ====================================================
          // Profile
          // ====================================================
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_outline_rounded,
              color: colorScheme.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${auth.userName} ${auth.position}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                auth.department,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),
        ],
      ),
    );
  }

  // ============================================================
  // 오늘 날짜
  // ============================================================

  String _todayText() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));

    final month = now.month.toString().padLeft(2, '0');

    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}.$month.$day';
  }
}

// ============================================================
// STEP 9. 글자 크기 순환 버튼
// ============================================================

class _TextScaleButton extends StatelessWidget {
  const _TextScaleButton();

  @override
  Widget build(BuildContext context) {
    final textScale = context.watch<TextScaleProvider>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: '글자 크기: ${textScale.mode.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          textScale.cycleMode();
        },
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                Icons.format_size_rounded,
                color: colorScheme.primary,
                size: _getIconSize(textScale.mode),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 현재 단계에 따라 아이콘 크기 변경
  // ==========================================================

  double _getIconSize(AppTextScaleMode mode) {
    switch (mode) {
      case AppTextScaleMode.system:
        return 20;

      case AppTextScaleMode.normal:
        return 20;

      case AppTextScaleMode.large:
        return 23;

      case AppTextScaleMode.extraLarge:
        return 26;
    }
  }
}

// ============================================================
// STEP 10. Sidebar Theme Toggle
// Light ↔ Dark 즉시 전환
// ============================================================

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: isDark ? '라이트 모드로 변경' : '다크 모드로 변경',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: () {
            context.read<ThemeModeProvider>().setMode(
              isDark ? AppThemeMode.light : AppThemeMode.dark,
            );
          },
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white70,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 11. Sidebar Account Profile
// ============================================================

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final userName = auth.userName.trim();

    final initial = userName.isNotEmpty
        ? userName.substring(0, 1).toUpperCase()
        : '의';

    return Tooltip(
      message: '${auth.userName} ${auth.position}\n${auth.department}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.round),
          onTap: () {
            context.go(AppRoutes.settings);
          },
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
