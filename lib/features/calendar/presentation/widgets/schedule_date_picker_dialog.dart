import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 공통 Date Picker 호출 함수
// 개인 일정 / 휴무 신청에서 공통 사용
// ============================================================

Future<DateTime?> showScheduleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      return ScheduleDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

// ============================================================
// STEP 2. Custom Schedule Date Picker
// ============================================================

class ScheduleDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ScheduleDatePickerDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<ScheduleDatePickerDialog> createState() =>
      _ScheduleDatePickerDialogState();
}

class _ScheduleDatePickerDialogState extends State<ScheduleDatePickerDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();

    final initial = _normalizeDate(widget.initialDate);

    _selectedDate = initial;

    _focusedMonth = DateTime(initial.year, initial.month, 1);
  }

  // ============================================================
  // STEP 3. 이전 달
  // ============================================================

  void _previousMonth() {
    final previous = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);

    if (!_monthContainsSelectableDate(previous)) {
      return;
    }

    setState(() {
      _focusedMonth = previous;
    });
  }

  // ============================================================
  // STEP 4. 다음 달
  // ============================================================

  void _nextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

    if (!_monthContainsSelectableDate(next)) {
      return;
    }

    setState(() {
      _focusedMonth = next;
    });
  }

  // ============================================================
  // STEP 5. 날짜 선택
  // ============================================================

  void _selectDate(DateTime date) {
    if (!_isSelectable(date)) {
      return;
    }

    setState(() {
      _selectedDate = _normalizeDate(date);

      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  // ============================================================
  // STEP 6. 오늘
  // ============================================================

  void _goToday() {
    final today = _normalizeDate(DateTime.now());

    if (!_isSelectable(today)) {
      return;
    }

    setState(() {
      _selectedDate = today;
      _focusedMonth = DateTime(today.year, today.month, 1);
    });
  }

  // ============================================================
  // STEP 7. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 430,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // Header
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '날짜 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: '닫기',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // Month Navigation
              // ==================================================
              Row(
                children: [
                  _NavigationButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _previousMonth,
                  ),

                  Expanded(
                    child: Text(
                      '${_focusedMonth.year}년 '
                      '${_focusedMonth.month}월',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _goToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(42, 32),
                    ),
                    child: const Text(
                      '오늘',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _NavigationButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // Weekday Header
              // ==================================================
              Row(
                children: List.generate(_weekdays.length, (index) {
                  Color color = context.appTextSecondary;

                  if (index == 0) {
                    color = AppColors.danger;
                  }

                  if (index == 6) {
                    color = AppColors.primaryBlue;
                  }

                  return Expanded(
                    child: Center(
                      child: Text(
                        _weekdays[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // Calendar Grid
              // ==================================================
              SizedBox(height: 260, child: _buildCalendarGrid()),

              const SizedBox(height: 14),

              Divider(height: 1, color: context.appBorder),

              const SizedBox(height: 14),

              // ==================================================
              // 선택 날짜 + Action
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatSelectedDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: context.appTextSecondary,
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedDate);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '선택',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 8. Calendar Grid
  // 항상 6주 × 7일
  // ============================================================

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    final firstDayOffset = firstDay.weekday % 7;

    final gridStart = firstDay.subtract(Duration(days: firstDayOffset));

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final date = gridStart.add(Duration(days: index));

        return _buildDayCell(date);
      },
    );
  }

  // ============================================================
  // STEP 9. Date Cell
  // ============================================================

  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth =
        date.month == _focusedMonth.month && date.year == _focusedMonth.year;

    final isSelected = _isSameDay(date, _selectedDate);

    final isToday = _isSameDay(date, DateTime.now());

    final isSelectable = _isSelectable(date);

    Color textColor = context.appTextPrimary;

    if (!isCurrentMonth || !isSelectable) {
      textColor = context.appTextDisabled;
    } else if (date.weekday == DateTime.sunday) {
      textColor = AppColors.danger;
    } else if (date.weekday == DateTime.saturday) {
      textColor = AppColors.primaryBlue;
    }

    if (isSelected) {
      textColor = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelectable
            ? () {
                _selectDate(date);
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primaryBlue, width: 1.2)
                : null,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected || isToday
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 10. 날짜 제한
  // ============================================================

  bool _isSelectable(DateTime date) {
    final normalized = _normalizeDate(date);

    if (widget.firstDate != null) {
      final first = _normalizeDate(widget.firstDate!);

      if (normalized.isBefore(first)) {
        return false;
      }
    }

    if (widget.lastDate != null) {
      final last = _normalizeDate(widget.lastDate!);

      if (normalized.isAfter(last)) {
        return false;
      }
    }

    return true;
  }

  bool _monthContainsSelectableDate(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);

    final lastDay = DateTime(month.year, month.month + 1, 0);

    if (widget.firstDate != null &&
        lastDay.isBefore(_normalizeDate(widget.firstDate!))) {
      return false;
    }

    if (widget.lastDate != null &&
        firstDay.isAfter(_normalizeDate(widget.lastDate!))) {
      return false;
    }

    return true;
  }

  // ============================================================
  // STEP 11. Helpers
  // ============================================================

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSelectedDate(DateTime date) {
    return '${date.year}년 '
        '${date.month}월 '
        '${date.day}일';
  }
}

// ============================================================
// STEP 12. Navigation Button
// ============================================================

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurfaceSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 19, color: context.appTextSecondary),
        ),
      ),
    );
  }
}
