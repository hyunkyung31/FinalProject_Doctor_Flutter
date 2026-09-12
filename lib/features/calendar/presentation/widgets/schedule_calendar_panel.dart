import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_schedule.dart';
import 'schedule_calendar_grid.dart';

// ============================================================
// STEP 1. Schedule Calendar Panel
// 월간 일정 Calendar 전체 영역
// ============================================================

class ScheduleCalendarPanel extends StatelessWidget {
  static const Color _personalScheduleColor = Color(0xFF7C6BC4);

  final DateTime focusedMonth;
  final DateTime selectedDate;

  final List<StaffSchedule> schedules;

  final Color Function(StaffSchedule schedule) scheduleColor;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final VoidCallback onCreateSchedule;

  final ValueChanged<DateTime> onDateSelected;

  const ScheduleCalendarPanel({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.schedules,
    required this.scheduleColor,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onCreateSchedule,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // ======================================================
          // Header
          // 월 + 범례 + Navigation + 일정 추가
          // ======================================================
          Row(
            children: [
              Text(
                '${focusedMonth.year}년 '
                '${focusedMonth.month}월',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(width: 22),

              // ==================================================
              // 일정 범례
              // ==================================================
              const _LegendItem(color: AppColors.primaryBlue, label: '진료'),

              const SizedBox(width: 13),

              const _LegendItem(color: AppColors.warning, label: '당직'),

              const SizedBox(width: 13),

              const _LegendItem(color: AppColors.textSecondary, label: '휴무'),

              const SizedBox(width: 13),

              const _LegendItem(color: _personalScheduleColor, label: '개인 일정'),

              const Spacer(),

              // ==================================================
              // 월 이동
              // ==================================================
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onPreviousMonth,
                    tooltip: '이전 달',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 21,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  TextButton(
                    onPressed: onToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '오늘',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: onNextMonth,
                    tooltip: '다음 달',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 21,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // ==================================================
              // 내 일정 추가
              // ==================================================
              TextButton.icon(
                onPressed: onCreateSchedule,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.surfaceSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  '내 일정 추가',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // 요일 Header
          // ======================================================
          const Row(
            children: [
              _WeekdayLabel(label: '일', isSunday: true),
              _WeekdayLabel(label: '월'),
              _WeekdayLabel(label: '화'),
              _WeekdayLabel(label: '수'),
              _WeekdayLabel(label: '목'),
              _WeekdayLabel(label: '금'),
              _WeekdayLabel(label: '토', isSaturday: true),
            ],
          ),

          const SizedBox(height: 8),

          // ======================================================
          // Calendar Grid
          // ======================================================
          Expanded(
            child: ScheduleCalendarGrid(
              focusedMonth: focusedMonth,
              selectedDate: selectedDate,
              schedules: schedules,
              scheduleColor: scheduleColor,
              onDateSelected: onDateSelected,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Weekday Label
// ============================================================

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isSunday;
  final bool isSaturday;

  const _WeekdayLabel({
    required this.label,
    this.isSunday = false,
    this.isSaturday = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textSecondary;

    if (isSunday) {
      color = AppColors.danger;
    }

    if (isSaturday) {
      color = AppColors.primaryBlue;
    }

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Legend
// ============================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 5),

        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
