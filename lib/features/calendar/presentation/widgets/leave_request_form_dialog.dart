import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import 'schedule_date_picker_dialog.dart';

// ============================================================
// STEP 1. 휴무 유형
// Backend AttendanceType Enum과 동일한 범위
// ============================================================

enum LeaveType {
  annual,
  morningHalf,
  afternoonHalf,
  hourly,
  sickLeave,
  officialLeave,
  businessTrip,
  education,
}

// ============================================================
// STEP 2. 휴무 유형 UI Helper
// ============================================================

extension LeaveTypeUiExtension on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.annual:
        return '연차';
      case LeaveType.morningHalf:
        return '오전 반차';
      case LeaveType.afternoonHalf:
        return '오후 반차';
      case LeaveType.hourly:
        return '시간차';
      case LeaveType.sickLeave:
        return '병가';
      case LeaveType.officialLeave:
        return '공가';
      case LeaveType.businessTrip:
        return '출장';
      case LeaveType.education:
        return '교육';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveType.annual:
        return Icons.calendar_month_outlined;
      case LeaveType.morningHalf:
        return Icons.wb_sunny_outlined;
      case LeaveType.afternoonHalf:
        return Icons.nights_stay_outlined;
      case LeaveType.hourly:
        return Icons.schedule_outlined;
      case LeaveType.sickLeave:
        return Icons.medical_services_outlined;
      case LeaveType.officialLeave:
        return Icons.account_balance_outlined;
      case LeaveType.businessTrip:
        return Icons.business_center_outlined;
      case LeaveType.education:
        return Icons.school_outlined;
    }
  }

  bool get isHalfDay {
    return this == LeaveType.morningHalf || this == LeaveType.afternoonHalf;
  }

  bool get isHourly {
    return this == LeaveType.hourly;
  }

  bool get isSingleDay {
    return isHalfDay || isHourly;
  }
}

// ============================================================
// STEP 3. 휴무 신청 결과
// 신청 사유는 사용하지 않음
// ============================================================

class LeaveRequestFormResult {
  final LeaveType leaveType;

  final DateTime startDate;
  final DateTime endDate;

  final String? startTime;
  final String? endTime;

  const LeaveRequestFormResult({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });
}

// ============================================================
// STEP 4. 휴무 신청 Dialog
// ============================================================

class LeaveRequestFormDialog extends StatefulWidget {
  const LeaveRequestFormDialog({super.key});

  @override
  State<LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}

class _LeaveRequestFormDialogState extends State<LeaveRequestFormDialog> {
  LeaveType _selectedLeaveType = LeaveType.annual;

  DateTime? _startDate;
  DateTime? _endDate;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _startDateError;
  String? _endDateError;
  String? _startTimeError;
  String? _endTimeError;

  // ============================================================
  // STEP 5. 휴무 유형 변경
  // ============================================================

  void _changeLeaveType(LeaveType type) {
    if (_selectedLeaveType == type) {
      return;
    }

    setState(() {
      _selectedLeaveType = type;

      _startDateError = null;
      _endDateError = null;
      _startTimeError = null;
      _endTimeError = null;

      if (type.isSingleDay && _startDate != null) {
        _endDate = _startDate;
      }

      if (!type.isHourly) {
        _startTime = null;
        _endTime = null;
      }
    });
  }

  // ============================================================
  // STEP 6. 시작일 선택
  // ============================================================

  Future<void> _selectStartDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final pickedDate = await showScheduleDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _startDate = pickedDate;
      _startDateError = null;

      if (_selectedLeaveType.isSingleDay) {
        _endDate = pickedDate;
        _endDateError = null;
        return;
      }

      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = null;
      }
    });
  }

  // ============================================================
  // STEP 7. 종료일 선택
  // ============================================================

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final firstDate = _startDate ?? today;

    final pickedDate = await showScheduleDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _endDate = pickedDate;
      _endDateError = null;
    });
  }

  // ============================================================
  // STEP 8. 시간차 시작 시간
  // ============================================================

  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _startTime = pickedTime;
      _startTimeError = null;

      if (_endTime != null &&
          _timeMinutes(_endTime!) <= _timeMinutes(pickedTime)) {
        _endTime = null;
      }
    });
  }

  // ============================================================
  // STEP 9. 시간차 종료 시간
  // ============================================================

  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _endTime = pickedTime;
      _endTimeError = null;
    });
  }

  // ============================================================
  // STEP 10. 신청
  // ============================================================

  void _submit() {
    bool hasError = false;

    setState(() {
      _startDateError = null;
      _endDateError = null;
      _startTimeError = null;
      _endTimeError = null;

      if (_startDate == null) {
        _startDateError = _selectedLeaveType.isSingleDay
            ? '휴무일을 선택해 주세요.'
            : '시작일을 선택해 주세요.';

        hasError = true;
      }

      if (!_selectedLeaveType.isSingleDay && _endDate == null) {
        _endDateError = '종료일을 선택해 주세요.';
        hasError = true;
      }

      if (_selectedLeaveType.isHourly) {
        if (_startTime == null) {
          _startTimeError = '시작 시간을 선택해 주세요.';
          hasError = true;
        }

        if (_endTime == null) {
          _endTimeError = '종료 시간을 선택해 주세요.';
          hasError = true;
        }

        if (_startTime != null &&
            _endTime != null &&
            _timeMinutes(_endTime!) <= _timeMinutes(_startTime!)) {
          _endTimeError = '종료 시간은 시작 시간보다 늦어야 합니다.';
          hasError = true;
        }
      }
    });

    if (hasError) {
      return;
    }

    final startDate = _startDate!;

    final endDate = _selectedLeaveType.isSingleDay ? startDate : _endDate!;

    Navigator.of(context).pop(
      LeaveRequestFormResult(
        leaveType: _selectedLeaveType,
        startDate: startDate,
        endDate: endDate,
        startTime: _selectedLeaveType.isHourly
            ? _formatTimeForApi(_startTime!)
            : null,
        endTime: _selectedLeaveType.isHourly
            ? _formatTimeForApi(_endTime!)
            : null,
      ),
    );
  }

  // ============================================================
  // STEP 11. Helper
  // ============================================================

  int _timeMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  // ============================================================
  // STEP 12. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // Header
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '휴무 신청',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '휴무 유형과 일정을 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      tooltip: '닫기',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        size: 21,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // 휴무 유형
              // ==================================================
              const _FieldLabel(label: '휴무 유형'),

              const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;

                  final itemWidth = (constraints.maxWidth - gap * 3) / 4;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: LeaveType.values
                        .map(
                          (type) => SizedBox(
                            width: itemWidth,
                            child: _LeaveTypeButton(
                              label: type.label,
                              icon: type.icon,
                              isSelected: _selectedLeaveType == type,
                              onTap: () {
                                _changeLeaveType(type);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // 휴무 날짜
              // ==================================================
              if (_selectedLeaveType.isSingleDay)
                _buildSingleDayField()
              else
                _buildDateRangeFields(),

              // ==================================================
              // 시간차 시간
              // ==================================================
              if (_selectedLeaveType.isHourly) ...[
                const SizedBox(height: 20),

                _buildHourlyTimeFields(),
              ],

              const SizedBox(height: 20),

              // ==================================================
              // 안내
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: AppColors.secondaryBlue,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        '휴무 신청은 승인 후 내 스케줄에 반영됩니다.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                    child: const Text('취소'),
                  ),

                  const SizedBox(width: 8),

                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(96, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      '신청하기',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
  // STEP 13. 날짜 범위
  // ============================================================

  Widget _buildDateRangeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: '휴무 기간'),

        const SizedBox(height: 9),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DateField(
                value: _startDate,
                placeholder: '시작일',
                errorText: _startDateError,
                onTap: _selectStartDate,
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(10, 13, 10, 0),
              child: Text('~'),
            ),

            Expanded(
              child: _DateField(
                value: _endDate,
                placeholder: '종료일',
                errorText: _endDateError,
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STEP 14. 단일 날짜
  // ============================================================

  Widget _buildSingleDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: '휴무일'),

        const SizedBox(height: 9),

        _DateField(
          value: _startDate,
          placeholder: '휴무일을 선택해 주세요.',
          errorText: _startDateError,
          onTap: _selectStartDate,
        ),
      ],
    );
  }

  // ============================================================
  // STEP 15. 시간차 시간 영역
  // ============================================================

  Widget _buildHourlyTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: '휴무 시간'),

        const SizedBox(height: 9),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TimeField(
                value: _startTime,
                placeholder: '시작 시간',
                errorText: _startTimeError,
                onTap: _selectStartTime,
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(10, 13, 10, 0),
              child: Text('~'),
            ),

            Expanded(
              child: _TimeField(
                value: _endTime,
                placeholder: '종료 시간',
                errorText: _endTimeError,
                onTap: _selectEndTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// STEP 16. Field Label
// ============================================================

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),

        const SizedBox(width: 3),

        const Text(
          '*',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 17. 휴무 유형 Button
// ============================================================

class _LeaveTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;

  final bool isSelected;
  final VoidCallback onTap;

  const _LeaveTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.appSurfaceSoft : context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : context.appBorder,
              width: isSelected ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.navy : context.appTextSecondary,
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.navy
                        : context.appTextSecondary,
                  ),
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
// STEP 18. 날짜 Field
// ============================================================

class _DateField extends StatelessWidget {
  final DateTime? value;
  final String placeholder;
  final String? errorText;
  final VoidCallback onTap;

  const _DateField({
    required this.value,
    required this.placeholder,
    required this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: errorText == null ? context.appBorder : AppColors.danger,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? placeholder : _formatDate(value!),
                    style: TextStyle(
                      fontSize: 12,
                      color: value == null
                          ? context.appTextDisabled
                          : context.appTextPrimary,
                    ),
                  ),
                ),

                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: AppColors.secondaryBlue,
                ),
              ],
            ),
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 5),

          Text(
            errorText!,
            style: const TextStyle(fontSize: 10.5, color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}.$month.$day';
  }
}

// ============================================================
// STEP 19. 시간 Field
// ============================================================

class _TimeField extends StatelessWidget {
  final TimeOfDay? value;
  final String placeholder;
  final String? errorText;
  final VoidCallback onTap;

  const _TimeField({
    required this.value,
    required this.placeholder,
    required this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: errorText == null ? context.appBorder : AppColors.danger,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? placeholder : _formatTime(value!),
                    style: TextStyle(
                      fontSize: 12,
                      color: value == null
                          ? context.appTextDisabled
                          : context.appTextPrimary,
                    ),
                  ),
                ),

                const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: AppColors.secondaryBlue,
                ),
              ],
            ),
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 5),

          Text(
            errorText!,
            style: const TextStyle(fontSize: 10.5, color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
