import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_shell.dart';

// ============================================================
// STEP 1. Staff Profile Page
// ============================================================

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('의료진 정보를 불러올 수 없습니다.')));
    }

    return AppShell(
      pageTitle: '내 프로필',
      selectedIndex: -1,
      body: Material(
        color: theme.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // 1. Profile Summary
                  // ==================================================
                  _ProfileSummaryCard(
                    name: auth.userName,
                    department: auth.department,
                    jobTitle: user.title.trim().isNotEmpty
                        ? user.title
                        : auth.displayPosition,
                    role: auth.displayPosition,
                    isDepartmentHead: auth.isDepartmentHead,
                    onSettingsTap: () {
                      context.go(AppRoutes.settings);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // 2. Account / Staff Information
                  // ==================================================
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ProfileInfoCard(
                            title: '계정 정보',
                            subtitle: '로그인 계정과 현재 인증 상태를 확인합니다.',
                            icon: Icons.badge_outlined,
                            rows: [
                              _ProfileInfoData(
                                label: '로그인 아이디',
                                value: user.username,
                              ),
                              _ProfileInfoData(
                                label: '직군',
                                value: auth.displayPosition,
                              ),
                              _ProfileInfoData(
                                label: '계정 상태',
                                value: user.isActive ? '활성' : user.status,
                                badge: user.isActive,
                              ),
                              _ProfileInfoData(
                                label: '사용자 ID',
                                value: user.id.toString(),
                                muted: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: _ProfileInfoCard(
                            title: '의료진 정보',
                            subtitle: '병원 내 의료진 소속과 직책 정보입니다.',
                            icon: Icons.local_hospital_outlined,
                            rows: [
                              _ProfileInfoData(
                                label: '이름',
                                value: user.name.trim().isNotEmpty
                                    ? user.name
                                    : '-',
                              ),
                              _ProfileInfoData(
                                label: '직원 ID',
                                value: user.staffId?.toString() ?? '-',
                                muted: true,
                              ),
                              if (user.doctorId != null)
                                _ProfileInfoData(
                                  label: '의사 ID',
                                  value: user.doctorId?.toString() ?? '-',
                                  muted: true,
                                ),
                              _ProfileInfoData(
                                label: '소속 부서',
                                value: user.departmentName.trim().isNotEmpty
                                    ? user.departmentName
                                    : '-',
                              ),
                              _ProfileInfoData(
                                label: '직책',
                                value: user.title.trim().isNotEmpty
                                    ? user.title
                                    : auth.displayPosition,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _ProfileInfoCard(
                          title: '계정 정보',
                          subtitle: '로그인 계정과 현재 인증 상태를 확인합니다.',
                          icon: Icons.badge_outlined,
                          rows: [
                            _ProfileInfoData(
                              label: '로그인 아이디',
                              value: user.username,
                            ),
                            _ProfileInfoData(
                              label: '직군',
                              value: auth.displayPosition,
                            ),
                            _ProfileInfoData(
                              label: '계정 상태',
                              value: user.isActive ? '활성' : user.status,
                              badge: user.isActive,
                            ),
                            _ProfileInfoData(
                              label: '사용자 ID',
                              value: user.id.toString(),
                              muted: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _ProfileInfoCard(
                          title: '의료진 정보',
                          subtitle: '병원 내 의료진 소속과 직책 정보입니다.',
                          icon: Icons.local_hospital_outlined,
                          rows: [
                            _ProfileInfoData(
                              label: '이름',
                              value: user.name.trim().isNotEmpty
                                  ? user.name
                                  : '-',
                            ),
                            _ProfileInfoData(
                              label: '직원 ID',
                              value: user.staffId?.toString() ?? '-',
                              muted: true,
                            ),
                            if (user.doctorId != null)
                              _ProfileInfoData(
                                label: '의사 ID',
                                value: user.doctorId?.toString() ?? '-',
                                muted: true,
                              ),
                            _ProfileInfoData(
                              label: '소속 부서',
                              value: user.departmentName.trim().isNotEmpty
                                  ? user.departmentName
                                  : '-',
                            ),
                            _ProfileInfoData(
                              label: '직책',
                              value: user.title.trim().isNotEmpty
                                  ? user.title
                                  : auth.displayPosition,
                            ),
                          ],
                        ),
                      ],
                    ),

                  // ==================================================
                  // 3. Department Head Permission
                  // ==================================================
                  if (auth.isDepartmentHead) ...[
                    const SizedBox(height: 16),

                    const _AuthorityCard(),
                  ],

                  const SizedBox(height: 16),

                  // ==================================================
                  // 4. Account Security
                  // ==================================================
                  _SecurityCard(
                    onSecurityTap: () {
                      context.go(AppRoutes.settings);
                    },
                    onLogoutTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2. Logout
  // ============================================================

  Future<void> _showLogoutDialog(BuildContext context) async {
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('현재 의료진 계정에서 로그아웃하시겠습니까?'),
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
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (result != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (!context.mounted) {
      return;
    }

    context.go(AppRoutes.login);
  }
}

// ============================================================
// STEP 4. Profile Summary Card
// ============================================================

class _ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String department;
  final String jobTitle;
  final String role;
  final bool isDepartmentHead;
  final VoidCallback onSettingsTap;

  const _ProfileSummaryCard({
    required this.name,
    required this.department,
    required this.jobTitle,
    required this.role,
    required this.isDepartmentHead,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // ======================================================
          // Avatar
          // ======================================================
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 34,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 18),

          // ======================================================
          // User
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    _RoleBadge(
                      label: isDepartmentHead ? '과장' : role,
                      emphasized: isDepartmentHead,
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  jobTitle,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      department,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          OutlinedButton.icon(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('설정'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Role Badge
// ============================================================

class _RoleBadge extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _RoleBadge({required this.label, required this.emphasized});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = emphasized
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.surfaceContainerHighest;

    final foregroundColor = emphasized
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Profile Information Data
// ============================================================

class _ProfileInfoData {
  final String label;
  final String value;
  final bool muted;
  final bool badge;

  const _ProfileInfoData({
    required this.label,
    required this.value,
    this.muted = false,
    this.badge = false,
  });
}

// ============================================================
// STEP 7. Profile Information Card
// ============================================================

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ProfileInfoData> rows;

  const _ProfileInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: colorScheme.primary),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // ======================================================
          // Information
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _InformationRow(data: rows[i]),

                  if (i != rows.length - 1)
                    Divider(height: 1, color: theme.dividerColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Information Row
// ============================================================

class _InformationRow extends StatelessWidget {
  final _ProfileInfoData data;

  const _InformationRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: Text(
              data.label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: data.badge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.value,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Text(
                    data.value,
                    style: TextStyle(
                      color: data.muted
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      fontSize: 11.5,
                      fontWeight: data.muted
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 9. Department Head Authority
// ============================================================

class _AuthorityCard extends StatelessWidget {
  const _AuthorityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: colorScheme.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '부서 관리자 권한',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '과장 직책으로 직원 휴무 승인 권한을 사용할 수 있습니다.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '휴무 승인',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10. Security Card
// ============================================================

class _SecurityCard extends StatelessWidget {
  final VoidCallback onSecurityTap;
  final VoidCallback onLogoutTap;

  const _SecurityCard({required this.onSecurityTap, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: colorScheme.primary,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계정 및 보안',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '로그인과 앱 보안 설정을 관리합니다.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          OutlinedButton.icon(
            onPressed: onSecurityTap,
            icon: const Icon(Icons.security_outlined, size: 15),
            label: const Text('보안 설정'),
          ),

          const SizedBox(width: 8),

          OutlinedButton.icon(
            onPressed: onLogoutTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.6)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 15),
            label: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
