import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_schedule.dart';
import '../../data/services/schedule_service.dart';

import 'schedule_date_picker_dialog.dart';
import 'schedule_time_picker_dialog.dart';

// ============================================================
// STEP 1. Schedule Form Dialog
// 개인 일정 등록 / 수정 공통 Dialog
// ============================================================

class ScheduleFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final DateTime initialDate;
  final StaffSchedule? schedule;

  const ScheduleFormDialog({
    super.key,
    required this.apiClient,
    required this.initialDate,
    this.schedule,
  });

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  static const String _scheduleType = 'PERSONAL';

  late DateTime _startDate;
  late DateTime _endDate;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);

  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  bool _isAllDay = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.schedule != null;

  // ============================================================
  // STEP 2. 초기값
  // ============================================================

  @override
  void initState() {
    super.initState();

    final schedule = widget.schedule;

    // ==========================================================
    // 수정 모드
    // ==========================================================

    if (schedule != null) {
      final start = schedule.startsAt;
      final end = schedule.endsAt;

      _isAllDay = schedule.isAllDay;

      _startDate = DateTime(start.year, start.month, start.day);

      _endDate = DateTime(end.year, end.month, end.day);

      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);

      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);

      _titleController = TextEditingController(text: schedule.title);

      _descriptionController = TextEditingController(
        text: schedule.description ?? '',
      );

      return;
    }

    // ==========================================================
    // 등록 모드
    // ==========================================================

    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _endDate = _startDate;

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. 시작 날짜 선택
  // Custom Schedule Date Picker 사용
  // ============================================================

  Future<void> _pickStartDate() async {
    final picked = await showScheduleDatePicker(
      context: context,
      initialDate: _startDate,

      // 개인 일정은 과거 일정 수정 가능
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;

      // 시작일이 종료일보다 뒤로 이동하면
      // 종료일도 시작일로 맞춤
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  // ============================================================
  // STEP 4. 종료 날짜 선택
  // ============================================================

  Future<void> _pickEndDate() async {
    final picked = await showScheduleDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = picked;
    });
  }

  // ============================================================
  // STEP 5. 시작 시간 선택
  // Custom Schedule Time Picker 사용
  // ============================================================

  Future<void> _pickStartTime() async {
    final picked = await showScheduleTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startTime = picked;
    });
  }

  // ============================================================
  // STEP 6. 종료 시간 선택
  // ============================================================

  Future<void> _pickEndTime() async {
    final picked = await showScheduleTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endTime = picked;
    });
  }

  // ============================================================
  // STEP 7. 등록 / 수정 실행
  // ============================================================

  Future<void> _submit() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showError('일정 제목을 입력해 주세요.');
      return;
    }

    late DateTime startsAt;
    late DateTime endsAt;

    // ==========================================================
    // 종일 일정
    // ==========================================================

    if (_isAllDay) {
      startsAt = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        0,
        0,
      );

      endsAt = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);
    }
    // ==========================================================
    // 시간 지정 일정
    // ==========================================================
    else {
      startsAt = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      endsAt = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );
    }

    // ==========================================================
    // 시간 검증
    // ==========================================================

    if (!endsAt.isAfter(startsAt)) {
      _showError('종료 일시는 시작 일시보다 늦어야 합니다.');

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final scheduleService = ScheduleService(apiClient: widget.apiClient);

      late StaffSchedule result;

      // ========================================================
      // 수정
      // ========================================================

      if (_isEditMode) {
        result = await scheduleService.updateSchedule(
          scheduleId: widget.schedule!.id,
          title: title,
          scheduleType: _scheduleType,
          startsAt: startsAt,
          endsAt: endsAt,
          description: _descriptionController.text.trim(),
          isAllDay: _isAllDay,
          color: _scheduleColorHex(),
        );
      }
      // ========================================================
      // 등록
      // ========================================================
      else {
        result = await scheduleService.createSchedule(
          title: title,
          scheduleType: _scheduleType,
          startsAt: startsAt,
          endsAt: endsAt,
          description: _descriptionController.text.trim(),
          isAllDay: _isAllDay,
          color: _scheduleColorHex(),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showError(_isEditMode ? '일정을 수정하지 못했습니다.' : '일정을 등록하지 못했습니다.');

      debugPrint(
        _isEditMode ? '[SCHEDULE UPDATE] $error' : '[SCHEDULE CREATE] $error',
      );
    }
  }

  // ============================================================
  // STEP 8. 개인 일정 Color
  // ============================================================

  String _scheduleColorHex() {
    return '#3D6F98';
  }

  // ============================================================
  // STEP 9. Error
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // STEP 10. Formatting
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}.$month.$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ============================================================
  // STEP 11. Field Label
  // ============================================================

  Widget _buildFieldLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.appTextPrimary,
          ),
        ),

        if (required) ...[
          const SizedBox(width: 3),

          const Text(
            '*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // STEP 12. 날짜 Button
  // ============================================================

  Widget _buildDateButton({
    required DateTime date,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 108,
      height: 34,
      child: Material(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: context.appTextSecondary,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    _formatDate(date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 13. 시간 Button
  // ============================================================

  Widget _buildTimeButton({
    required TimeOfDay time,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 78,
      height: 34,
      child: Material(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: context.appTextSecondary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    _formatTime(time),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 14. 시작 / 종료 Row
  // 날짜는 항상 표시
  // 시간은 종일 OFF일 때만 즉시 표시
  // 별도 Animation 없음
  // ============================================================

  Widget _buildDateTimeRow({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback? onDatePressed,
    required VoidCallback? onTimePressed,
  }) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // ======================================================
          // Label
          // ======================================================
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          const Spacer(),

          // ======================================================
          // 날짜
          // ======================================================
          _buildDateButton(date: date, onPressed: onDatePressed),

          // ======================================================
          // 시간
          // 하루 종일 OFF일 때만 바로 표시
          // ======================================================
          if (!_isAllDay) ...[
            const SizedBox(width: 8),

            _buildTimeButton(time: time, onPressed: onTimePressed),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 15. Section Container
  // 제목 위치를 조금 위로 조정
  // ============================================================

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,

      // 위쪽만 12로 줄여서
      // 일정 제목 / 일정 일시 / 메모 제목을 위로 이동
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),

      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),

      child: child,
    );
  }

  // ============================================================
  // STEP 16. InputDecoration
  // ============================================================

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: context.appTextDisabled),
      filled: true,
      fillColor: context.appSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.appBorder),
      ),
    );
  }

  // ============================================================
  // STEP 17. Dialog UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,

      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 500,
          maxWidth: 500,
          maxHeight: screenHeight * 0.88,
        ),

        child: Container(
          decoration: BoxDecoration(
            // 사용자가 선택한 회색 계열 Dialog 배경
            color: context.appBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // Header
              // ==================================================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==============================================
                    // Header Icon
                    // ==============================================
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.appSurfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        size: 21,
                        color: context.appBrand,
                      ),
                    ),

                    const SizedBox(width: 13),

                    // ==============================================
                    // Header Title
                    // ==============================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _isEditMode ? '일정 수정' : '일정 등록',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.appTextPrimary,
                                ),
                              ),

                              if (_isEditMode) ...[
                                const SizedBox(width: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appSurfaceSoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '수정',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _isEditMode
                                ? '등록된 개인 일정을 수정합니다.'
                                : '회의, 교육, 학회 등 개인 일정을 등록합니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      tooltip: '닫기',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 21,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Header / Body 구분선은 유지
              Divider(height: 1, color: context.appBorder),

              // ==================================================
              // Scrollable Body
              // ==================================================
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================================
                      // 일정 제목
                      // ============================================
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('일정 제목', required: true),

                            const SizedBox(height: 10),

                            TextField(
                              controller: _titleController,
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: '예: 심장내과 컨퍼런스',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ============================================
                      // 일정 일시
                      // ============================================
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('일정 일시', required: true),

                            const SizedBox(height: 10),

                            // ========================================
                            // 날짜 / 시간 Container
                            // ========================================
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.appSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.appBorder),
                              ),

                              child: Column(
                                children: [
                                  // ==================================
                                  // 하루 종일
                                  // ==================================
                                  SizedBox(
                                    height: 48,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '하루 종일',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: context.appTextPrimary,
                                            ),
                                          ),

                                          const Spacer(),

                                          SizedBox(
                                            width: 42,
                                            height: 26,
                                            child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Switch.adaptive(
                                                value: _isAllDay,
                                                activeTrackColor:
                                                    AppColors.primaryBlue,
                                                onChanged: _isSubmitting
                                                    ? null
                                                    : (value) {
                                                        setState(() {
                                                          _isAllDay = value;
                                                        });
                                                      },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Divider(height: 1, color: context.appBorder),

                                  // ==================================
                                  // 시작
                                  // ==================================
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: _buildDateTimeRow(
                                      label: '시작',
                                      date: _startDate,
                                      time: _startTime,
                                      onDatePressed: _isSubmitting
                                          ? null
                                          : _pickStartDate,
                                      onTimePressed: _isSubmitting
                                          ? null
                                          : _pickStartTime,
                                    ),
                                  ),

                                  Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                    color: context.appBorder,
                                  ),

                                  // ==================================
                                  // 종료
                                  // ==================================
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: _buildDateTimeRow(
                                      label: '종료',
                                      date: _endDate,
                                      time: _endTime,
                                      onDatePressed: _isSubmitting
                                          ? null
                                          : _pickEndDate,
                                      onTimePressed: _isSubmitting
                                          ? null
                                          : _pickEndTime,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ========================================
                            // 종일 안내
                            // ========================================
                            if (_isAllDay) ...[
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: AppColors.secondaryBlue,
                                  ),

                                  SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      '종일 일정은 선택한 날짜 전체로 등록됩니다.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ============================================
                      // 메모
                      // ============================================
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '메모',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextField(
                              controller: _descriptionController,
                              enabled: !_isSubmitting,
                              minLines: 2,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                hintText: '필요한 내용을 입력해 주세요.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // Footer
              // Footer 위 Divider는 제거
              // ==================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),

                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '* 필수 입력 항목',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appTextDisabled,
                        ),
                      ),
                    ),

                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appTextSecondary,
                        minimumSize: const Size(82, 42),
                        side: BorderSide(color: context.appBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(92, 42),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isEditMode
                                      ? Icons.save_outlined
                                      : Icons.add_circle_outline_rounded,
                                  size: 16,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  _isEditMode ? '저장' : '일정 등록',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
