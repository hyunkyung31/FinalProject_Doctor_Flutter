import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_schedule.dart';
import 'schedule_detail_card.dart';

// ============================================================
// STEP 1. Schedule Detail Panel
// 선택 날짜 우측 상세 영역
// ============================================================

class ScheduleDetailPanel extends StatelessWidget {
  final DateTime selectedDate;
  final List<StaffSchedule> schedules;

  final Color Function(StaffSchedule schedule) scheduleColor;

  final void Function(StaffSchedule schedule) onEdit;
  final void Function(StaffSchedule schedule) onDelete;

  const ScheduleDetailPanel({
    super.key,
    required this.selectedDate,
    required this.schedules,
    required this.scheduleColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // 선택 날짜
          // ======================================================
          Text(
            _formatFullDate(selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            schedules.isEmpty ? '등록된 일정이 없습니다.' : '${schedules.length}개의 일정',
            style: TextStyle(
              fontSize: 11,
              color: context.appTextSecondary,
            ),
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: context.appBorder),

          // ======================================================
          // 일정 목록
          // ======================================================
          Expanded(
            child: schedules.isEmpty
                ? const _EmptyScheduleDetail()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: schedules.length,
                    separatorBuilder: (context, index) {
                      return Divider(height: 1, color: context.appBorder);
                    },
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];

                      return ScheduleDetailCard(
                        schedule: schedule,
                        color: scheduleColor(schedule),
                        timeText: _formatScheduleTime(schedule),
                        onEdit: () {
                          onEdit(schedule);
                        },
                        onDelete: () {
                          onDelete(schedule);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2. 일정 시간 표시
  // ============================================================

  String _formatScheduleTime(StaffSchedule schedule) {
    if (schedule.isAllDay) {
      return '종일';
    }

    final start = schedule.startsAt.toLocal();
    final end = schedule.endsAt.toLocal();

    final startText = _formatTime(start);
    final endText = _formatTime(end);

    final isNextDay =
        start.year != end.year ||
        start.month != end.month ||
        start.day != end.day;

    if (isNextDay) {
      return '$startText - 익일 $endText';
    }

    return '$startText - $endText';
  }

  // ============================================================
  // STEP 3. 시간 Formatting
  // ============================================================

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ============================================================
  // STEP 4. 날짜 Formatting
  // ============================================================

  String _formatFullDate(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

    return '${date.year}년 '
        '${date.month}월 '
        '${date.day}일 '
        '${weekdays[date.weekday - 1]}';
  }
}

// ============================================================
// STEP 5. Empty State
// ============================================================

class _EmptyScheduleDetail extends StatelessWidget {
  const _EmptyScheduleDetail();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.secondaryBlue,
              size: 22,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '일정이 없습니다.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '다른 날짜를 선택해 주세요.',
            style: TextStyle(fontSize: 11, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}
