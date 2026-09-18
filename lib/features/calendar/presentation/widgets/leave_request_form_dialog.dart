import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import 'schedule_date_picker_dialog.dart';

// ============================================================
// STEP 1. 휴무 유형
// ============================================================

enum LeaveType { annual, morningHalf, afternoonHalf }

// ============================================================
// STEP 2. 휴무 신청 결과
// ============================================================

class LeaveRequestFormResult {
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const LeaveRequestFormResult({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });
}

// ============================================================
// STEP 3. 휴무 신청 Dialog
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

  final TextEditingController _reasonController = TextEditingController();

  String? _startDateError;
  String? _endDateError;
  String? _reasonError;

  bool get _isHalfDay {
    return _selectedLeaveType == LeaveType.morningHalf ||
        _selectedLeaveType == LeaveType.afternoonHalf;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 4. 휴무 유형 변경
  // ============================================================

  void _changeLeaveType(LeaveType type) {
    if (_selectedLeaveType == type) {
      return;
    }

    setState(() {
      _selectedLeaveType = type;

      _startDateError = null;
      _endDateError = null;

      if (type == LeaveType.morningHalf || type == LeaveType.afternoonHalf) {
        if (_startDate != null) {
          _endDate = _startDate;
        }
      }
    });
  }

  // ============================================================
  // STEP 5. 시작일 / 반차 휴무일 선택
  // 공통 Custom Calendar 사용
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

      // ==========================================================
      // 반차는 시작일 = 종료일
      // ==========================================================

      if (_isHalfDay) {
        _endDate = pickedDate;
        _endDateError = null;
        return;
      }

      // ==========================================================
      // 시작일 변경 후 기존 종료일이 더 앞이면 초기화
      // ==========================================================

      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = null;
      }
    });
  }

  // ============================================================
  // STEP 6. 연차 종료일 선택
  // 공통 Custom Calendar 사용
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
  // STEP 7. 신청
  // ============================================================

  void _submit() {
    final reason = _reasonController.text.trim();

    bool hasError = false;

    setState(() {
      _startDateError = null;
      _endDateError = null;
      _reasonError = null;

      if (_startDate == null) {
        _startDateError = _isHalfDay ? '휴무일을 선택해 주세요.' : '시작일을 선택해 주세요.';

        hasError = true;
      }

      if (!_isHalfDay && _endDate == null) {
        _endDateError = '종료일을 선택해 주세요.';
        hasError = true;
      }

      if (reason.isEmpty) {
        _reasonError = '신청 사유를 입력해 주세요.';
        hasError = true;
      }
    });

    if (hasError) {
      return;
    }

    final startDate = _startDate!;

    final endDate = _isHalfDay ? startDate : _endDate!;

    Navigator.of(context).pop(
      LeaveRequestFormResult(
        leaveType: _selectedLeaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      ),
    );
  }

  // ============================================================
  // STEP 8. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
                    child: Text(
                      '휴무 신청',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
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
              // 휴무 유형
              // ==================================================
              const _FieldLabel(label: '휴무 유형'),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _LeaveTypeButton(
                      label: '연차',
                      isSelected: _selectedLeaveType == LeaveType.annual,
                      onTap: () {
                        _changeLeaveType(LeaveType.annual);
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _LeaveTypeButton(
                      label: '오전 반차',
                      isSelected: _selectedLeaveType == LeaveType.morningHalf,
                      onTap: () {
                        _changeLeaveType(LeaveType.morningHalf);
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _LeaveTypeButton(
                      label: '오후 반차',
                      isSelected: _selectedLeaveType == LeaveType.afternoonHalf,
                      onTap: () {
                        _changeLeaveType(LeaveType.afternoonHalf);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // 날짜
              // ==================================================
              if (_isHalfDay) _buildHalfDayField() else _buildAnnualFields(),

              const SizedBox(height: 18),

              // ==================================================
              // 신청 사유
              // ==================================================
              const _FieldLabel(label: '신청 사유'),

              const SizedBox(height: 8),

              TextField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 3,
                maxLength: 200,
                onChanged: (value) {
                  if (_reasonError != null && value.trim().isNotEmpty) {
                    setState(() {
                      _reasonError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '휴무 신청 사유를 입력해 주세요.',
                  errorText: _reasonError,
                  filled: true,
                  fillColor: context.appSurface,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(
                      color: _reasonError == null
                          ? context.appBorder
                          : AppColors.danger,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // 안내
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.secondaryBlue,
                    ),

                    SizedBox(width: 8),

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

              const SizedBox(height: 18),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('신청하기'),
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
  // STEP 9. 연차 날짜 영역
  // ============================================================

  Widget _buildAnnualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: '휴무 기간'),

        const SizedBox(height: 8),

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
  // STEP 10. 반차 날짜 영역
  // ============================================================

  Widget _buildHalfDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: '휴무일'),

        const SizedBox(height: 8),

        _DateField(
          value: _startDate,
          placeholder: '휴무일을 선택해 주세요.',
          errorText: _startDateError,
          onTap: _selectStartDate,
        ),
      ],
    );
  }
}

// ============================================================
// STEP 11. Field Label
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
// STEP 12. 휴무 유형 Button
// ============================================================

class _LeaveTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeaveTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.appSurfaceSoft : context.appSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : context.appBorder,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.navy : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 13. 날짜 Field
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
            height: 44,
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
