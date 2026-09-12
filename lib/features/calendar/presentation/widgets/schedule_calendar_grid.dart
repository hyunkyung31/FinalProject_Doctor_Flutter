import 'package:flutter/material.dart';

import '../../data/models/staff_schedule.dart';
import 'schedule_day_cell.dart';

// ============================================================
// STEP 1. Schedule Calendar Grid
// 월간 날짜 계산 + Calendar Grid
// ============================================================

class ScheduleCalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;

  final List<StaffSchedule> schedules;

  final Color Function(StaffSchedule schedule) scheduleColor;

  final ValueChanged<DateTime> onDateSelected;

  const ScheduleCalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.schedules,
    required this.scheduleColor,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);

    // ==========================================================
    // Dart weekday
    // Monday = 1 ... Sunday = 7
    //
    // Calendar
    // Sunday = 0 ... Saturday = 6
    // ==========================================================

    final firstDayOffset = firstDay.weekday % 7;

    // ==========================================================
    // 현재 월의 마지막 날짜
    // ==========================================================

    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;

    // ==========================================================
    // 필요한 주 수 계산
    //
    // 5주 → 35칸
    // 6주 → 42칸
    // ==========================================================

    final weekCount = ((firstDayOffset + daysInMonth) / 7).ceil();

    final itemCount = weekCount * 7;

    final gridStartDate = firstDay.subtract(Duration(days: firstDayOffset));

    final today = DateTime.now();

    // ==========================================================
    // 실제 사용 가능한 높이를 주 수에 맞게 분배
    // ==========================================================

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / weekCount;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: cellHeight,
          ),
          itemBuilder: (context, index) {
            final date = gridStartDate.add(Duration(days: index));

            final isCurrentMonth =
                date.year == focusedMonth.year &&
                date.month == focusedMonth.month;

            // ==================================================
            // 이전 / 다음 달 Cell에는 일정 Chip 숨김
            // ==================================================

            final daySchedules = isCurrentMonth
                ? _schedulesForDate(schedules, date)
                : <StaffSchedule>[];

            return ScheduleDayCell(
              date: date,
              isCurrentMonth: isCurrentMonth,
              isToday: _isSameDate(date, today),
              isSelected: _isSameDate(date, selectedDate),
              schedules: daySchedules,
              scheduleColor: scheduleColor,
              onTap: () {
                onDateSelected(date);
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STEP 2. 날짜별 일정 필터
  // Calendar 전용
  // ============================================================

  List<StaffSchedule> _schedulesForDate(
    List<StaffSchedule> schedules,
    DateTime date,
  ) {
    final result = schedules.where((schedule) {
      final start = schedule.startsAt.toLocal();

      return start.year == date.year &&
          start.month == date.month &&
          start.day == date.day;
    }).toList();

    result.sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return result;
  }

  // ============================================================
  // STEP 3. 같은 날짜 확인
  // ============================================================

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
