import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 공통 Time Picker 호출 함수
// 개인 일정 시작 / 종료 시간에서 공통 사용
// ============================================================

Future<TimeOfDay?> showScheduleTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      return ScheduleTimePickerDialog(initialTime: initialTime);
    },
  );
}

// ============================================================
// STEP 2. Custom Schedule Time Picker
// 24시간 형식
// 시 / 분 Wheel Picker
// ============================================================

class ScheduleTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const ScheduleTimePickerDialog({super.key, required this.initialTime});

  @override
  State<ScheduleTimePickerDialog> createState() =>
      _ScheduleTimePickerDialogState();
}

class _ScheduleTimePickerDialogState extends State<ScheduleTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();

    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);

    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. 선택 완료
  // ============================================================

  void _submit() {
    Navigator.of(
      context,
    ).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  // ============================================================
  // STEP 4. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
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
                  const Expanded(
                    child: Text(
                      '시간 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // 현재 선택 시간 Preview
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatTime(_selectedHour, _selectedMinute),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // 시 / 분 Label
              // ==================================================
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      '시',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  SizedBox(width: 28),

                  Expanded(
                    child: Text(
                      '분',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ==================================================
              // Wheel Picker
              // ==================================================
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    // ============================================
                    // Hour
                    // ============================================
                    Expanded(
                      child: _TimeWheel(
                        controller: _hourController,
                        itemCount: 24,
                        selectedIndex: _selectedHour,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedHour = index;
                          });
                        },
                      ),
                    ),

                    // ============================================
                    // Colon
                    // ============================================
                    const SizedBox(
                      width: 28,
                      child: Center(
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // ============================================
                    // Minute
                    // ============================================
                    Expanded(
                      child: _TimeWheel(
                        controller: _minuteController,
                        itemCount: 60,
                        selectedIndex: _selectedMinute,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinute = index;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Divider(height: 1, color: AppColors.border),

              const SizedBox(height: 14),

              // ==================================================
              // Actions
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
                    onPressed: _submit,
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
  // STEP 5. 시간 문자열
  // ============================================================

  String _formatTime(int hour, int minute) {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');

    return '$hourText:$minuteText';
  }
}

// ============================================================
// STEP 6. Time Wheel
// 시 / 분 공통 Wheel
// ============================================================

class _TimeWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int> onSelectedItemChanged;

  const _TimeWheel({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.onSelectedItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ======================================================
        // 가운데 선택 영역 배경
        // ======================================================
        IgnorePointer(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),

        // ======================================================
        // Wheel
        // ======================================================
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 44,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.6,
          perspective: 0.002,
          overAndUnderCenterOpacity: 0.35,
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected = index == selectedIndex;

              return Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: isSelected ? 17 : 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.navy
                        : AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
