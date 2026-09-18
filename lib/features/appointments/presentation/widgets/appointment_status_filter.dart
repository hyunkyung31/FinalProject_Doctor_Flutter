import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../appointment_ui_model.dart';

// ============================================================
// STEP 1. Status Filter
// ============================================================

enum AppointmentStatusFilter { all, requested, accepted, canceled }

// ============================================================
// STEP 2. Status Filter Bar
// ============================================================

class AppointmentStatusFilterBar extends StatelessWidget {
  final AppointmentStatusFilter selectedFilter;

  final int totalCount;
  final int requestedCount;
  final int acceptedCount;
  final int canceledCount;

  final bool canManage;

  final ValueChanged<AppointmentStatusFilter> onChanged;

  const AppointmentStatusFilterBar({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.requestedCount,
    required this.acceptedCount,
    required this.canceledCount,
    required this.canManage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ======================================================
        // 상태 Filter
        // ======================================================
        _FilterButton(
          label: '전체',
          count: totalCount,
          selected: selectedFilter == AppointmentStatusFilter.all,
          onTap: () {
            onChanged(AppointmentStatusFilter.all);
          },
        ),

        const SizedBox(width: 8),

        _FilterButton(
          label: '승인 대기',
          count: requestedCount,
          selected: selectedFilter == AppointmentStatusFilter.requested,
          status: AppointmentStatus.requested,
          onTap: () {
            onChanged(AppointmentStatusFilter.requested);
          },
        ),

        const SizedBox(width: 8),

        _FilterButton(
          label: '예약 승인',
          count: acceptedCount,
          selected: selectedFilter == AppointmentStatusFilter.accepted,
          status: AppointmentStatus.accepted,
          onTap: () {
            onChanged(AppointmentStatusFilter.accepted);
          },
        ),

        const SizedBox(width: 8),

        _FilterButton(
          label: '예약 취소',
          count: canceledCount,
          selected: selectedFilter == AppointmentStatusFilter.canceled,
          status: AppointmentStatus.canceled,
          onTap: () {
            onChanged(AppointmentStatusFilter.canceled);
          },
        ),

        const Spacer(),

        // ======================================================
        // 현재 역할 안내
        // ======================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: canManage
                ? AppColors.successBackground
                : context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                canManage
                    ? Icons.verified_user_outlined
                    : Icons.visibility_outlined,
                size: 14,
                color: canManage ? AppColors.success : context.appTextSecondary,
              ),

              const SizedBox(width: 5),

              Text(
                canManage ? '예약 승인 가능' : '예약 조회 전용',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: canManage
                      ? AppColors.success
                      : context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 3. Filter Button
// ============================================================

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;

  final AppointmentStatus? status;

  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : context.appSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.navy : context.appBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.white : color,
                  ),
                ),

                const SizedBox(width: 6),
              ],

              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.appTextPrimary,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case AppointmentStatus.requested:
        return AppColors.warning;

      case AppointmentStatus.accepted:
        return AppColors.success;

      case AppointmentStatus.canceled:
        return AppColors.danger;

      case null:
        return context.appTextSecondary;
    }
  }
}
