import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_schedule.dart';

// ============================================================
// STEP 1. Schedule Day Cell
// Calendar 날짜 1칸
// ============================================================

class ScheduleDayCell extends StatelessWidget {
  final DateTime date;

  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;

  final List<StaffSchedule> schedules;

  final Color Function(StaffSchedule schedule) scheduleColor;

  final VoidCallback onTap;

  const ScheduleDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.schedules,
    required this.scheduleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.border.withValues(alpha: 0.65),
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDate(),

                const SizedBox(height: 4),

                Expanded(child: _buildSchedules()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2. 날짜
  // ============================================================

  Widget _buildDate() {
    if (isToday || isSelected) {
      return Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: 25,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _dateColor(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 3. 일정 목록
  // 최대 2개 표시 + 추가 일정은 가운데 +n
  // ============================================================

  Widget _buildSchedules() {
    if (schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleSchedules = schedules.take(2).toList();

    final hiddenCount = schedules.length - visibleSchedules.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // 최대 2개 일정 표시
        // ========================================================
        for (int i = 0; i < visibleSchedules.length; i++) ...[
          _ScheduleChip(
            schedule: visibleSchedules[i],
            color: scheduleColor(visibleSchedules[i]),
          ),

          if (i != visibleSchedules.length - 1) const SizedBox(height: 3),
        ],

        // ========================================================
        // 숨겨진 일정 개수
        // ========================================================
        if (hiddenCount > 0) ...[
          const SizedBox(height: 3),

          SizedBox(
            width: double.infinity,
            child: Text(
              '+$hiddenCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // STEP 4. 날짜 색상
  // ============================================================

  Color _dateColor() {
    if (!isCurrentMonth) {
      return AppColors.textDisabled;
    }

    if (date.weekday == DateTime.sunday) {
      return AppColors.danger;
    }

    if (date.weekday == DateTime.saturday) {
      return AppColors.primaryBlue;
    }

    return AppColors.textPrimary;
  }
}

// ============================================================
// STEP 5. Schedule Chip
// 기존 [● 진료] 형태 복구
// ============================================================

class _ScheduleChip extends StatelessWidget {
  final StaffSchedule schedule;
  final Color color;

  const _ScheduleChip({required this.schedule, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 19,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              _scheduleLabel(schedule),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _scheduleLabel(StaffSchedule schedule) {
    switch (schedule.scheduleType) {
      case 'CLINICAL':
        return '진료';

      case 'ON_CALL':
        return '당직';

      case 'OFF':
        return '휴무';

      case 'PERSONAL':
        return schedule.title;

      default:
        return schedule.title;
    }
  }
}
