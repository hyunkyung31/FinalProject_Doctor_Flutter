import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../appointment_ui_model.dart';

class AppointmentCalendarPanel extends StatefulWidget {
  final List<AppointmentUiModel> appointments;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const AppointmentCalendarPanel({
    super.key,
    required this.appointments,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<AppointmentCalendarPanel> createState() =>
      _AppointmentCalendarPanelState();
}

class _AppointmentCalendarPanelState extends State<AppointmentCalendarPanel> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();

    _focusedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  void didUpdateWidget(covariant AppointmentCalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _focusedMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  int _countForDate(DateTime date) {
    return widget.appointments.where((appointment) {
      final local = appointment.reservedAt.toLocal();

      return local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).length;
  }

  int _countStatus(AppointmentStatus status) {
    return widget.appointments
        .where((appointment) => appointment.status == status)
        .length;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
  }

  void _goToday() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _focusedMonth = DateTime(today.year, today.month);
    });

    widget.onDateChanged(today);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final startOffset = firstDay.weekday % 7;

    final calendarCellCount = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '예약 달력',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _goToday,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '오늘',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _moveMonth(-1),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                ),
                Expanded(
                  child: Text(
                    '${_focusedMonth.year}년 '
                    '${_focusedMonth.month}월',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _moveMonth(1),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (var index = 0; index < weekdays.length; index++)
                  Expanded(
                    child: Text(
                      weekdays[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: index == 0
                            ? AppColors.danger
                            : index == 6
                            ? AppColors.primaryBlue
                            : context.appTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calendarCellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayNumber,
                );

                final selected = _sameDate(date, widget.selectedDate);

                final isToday = _sameDate(date, today);

                final count = _countForDate(date);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onDateChanged(date);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue
                            : count > 0
                            ? context.appSurfaceSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : isToday
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: selected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : context.appTextPrimary,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$count건',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: context.appBorder),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '전체 예약 현황',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.appointments.length}건',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCount(
                        label: '승인 대기',
                        count: _countStatus(AppointmentStatus.requested),
                        foreground: AppColors.warning,
                        background: AppColors.warningBackground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SummaryCount(
                        label: '예약 승인',
                        count: _countStatus(AppointmentStatus.accepted),
                        foreground: AppColors.success,
                        background: AppColors.successBackground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SummaryCount(
                        label: '예약 취소',
                        count: _countStatus(AppointmentStatus.canceled),
                        foreground: AppColors.danger,
                        background: AppColors.dangerBackground,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: context.appTextSecondary,
                      ),
                      SizedBox(width: 7),
                      Text(
                        '운영시간 08:30 ~ 18:00 · 30분 단위',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  final String label;
  final int count;
  final Color foreground;
  final Color background;

  const _SummaryCount({
    required this.label,
    required this.count,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
