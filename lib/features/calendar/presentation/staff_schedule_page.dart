import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/models/staff_schedule.dart';
import '../data/services/schedule_service.dart';

import 'widgets/schedule_form_dialog.dart';
import 'widgets/schedule_detail_panel.dart';
import 'widgets/schedule_calendar_panel.dart';
import 'widgets/schedule_section_tabs.dart';
import 'widgets/leave_request_panel.dart';
import 'widgets/leave_request_form_dialog.dart';

// ============================================================
// STEP 1. Staff Schedule Page
// 월간 의료진 일정
// ============================================================
// ============================================================
// 일정 Page Tab
// ============================================================

class StaffSchedulePage extends StatefulWidget {
  const StaffSchedulePage({super.key});

  @override
  State<StaffSchedulePage> createState() => _StaffSchedulePageState();
}

class _StaffSchedulePageState extends State<StaffSchedulePage> {
  late Future<List<StaffSchedule>> _scheduleFuture;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  ScheduleSection _selectedSection = ScheduleSection.mySchedule;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _focusedMonth = DateTime(now.year, now.month, 1);

    _selectedDate = DateTime(now.year, now.month, now.day);

    _scheduleFuture = _loadSchedules();
  }

  // ============================================================
  // STEP 2. API 일정 조회
  // ============================================================

  Future<List<StaffSchedule>> _loadSchedules() {
    final apiClient = context.read<ApiClient>();

    final scheduleService = ScheduleService(apiClient: apiClient);

    return scheduleService.fetchSchedules();
  }

  void _reload() {
    setState(() {
      _scheduleFuture = _loadSchedules();
    });
  }

  // ============================================================
  // STEP 3. 월 이동
  // ============================================================

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);

      _selectedDate = _focusedMonth;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

      _selectedDate = _focusedMonth;
    });
  }

  void _goToday() {
    final now = DateTime.now();

    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);

      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  // ============================================================
  // 날짜 선택
  // ============================================================

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);

      // ==========================================================
      // 이전 / 다음 달 Cell 선택 시 해당 월로 이동
      // ==========================================================

      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  // ============================================================
  // STEP 3-1. 일정 등록 Dialog
  // ============================================================

  Future<void> _openCreateScheduleDialog() async {
    final apiClient = context.read<ApiClient>();

    final createdSchedule = await showDialog<StaffSchedule>(
      context: context,
      builder: (dialogContext) {
        return ScheduleFormDialog(
          apiClient: apiClient,
          initialDate: _selectedDate,
        );
      },
    );

    if (createdSchedule == null || !mounted) {
      return;
    }

    // ==========================================================
    // 등록된 일정 날짜로 이동 + 서버 일정 새로 조회
    // ==========================================================

    setState(() {
      _focusedMonth = DateTime(
        createdSchedule.startsAt.year,
        createdSchedule.startsAt.month,
        1,
      );

      _selectedDate = DateTime(
        createdSchedule.startsAt.year,
        createdSchedule.startsAt.month,
        createdSchedule.startsAt.day,
      );

      _scheduleFuture = _loadSchedules();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정이 등록되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // STEP 3-2. 일정 수정 Dialog
  // ============================================================

  Future<void> _openEditScheduleDialog(StaffSchedule schedule) async {
    final apiClient = context.read<ApiClient>();

    final updatedSchedule = await showDialog<StaffSchedule>(
      context: context,
      builder: (dialogContext) {
        return ScheduleFormDialog(
          apiClient: apiClient,
          initialDate: DateTime(
            schedule.startsAt.year,
            schedule.startsAt.month,
            schedule.startsAt.day,
          ),
          schedule: schedule,
        );
      },
    );

    if (updatedSchedule == null || !mounted) {
      return;
    }

    // ==========================================================
    // 수정된 일정 날짜로 이동
    // ==========================================================

    setState(() {
      _focusedMonth = DateTime(
        updatedSchedule.startsAt.year,
        updatedSchedule.startsAt.month,
        1,
      );

      _selectedDate = DateTime(
        updatedSchedule.startsAt.year,
        updatedSchedule.startsAt.month,
        updatedSchedule.startsAt.day,
      );

      // ========================================================
      // 수정 후 서버 일정 다시 조회
      // ========================================================

      _scheduleFuture = _loadSchedules();
    });

    // ==========================================================
    // 수정 완료 안내
    // ==========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정이 수정되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // STEP 3-3. 일정 삭제
  // ============================================================

  Future<void> _deleteSchedule(StaffSchedule schedule) async {
    // ==========================================================
    // 삭제 확인 Dialog
    // ==========================================================

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text(
            "'${schedule.title}' 일정을 삭제하시겠습니까?\n"
            '삭제한 일정은 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    // ==========================================================
    // DELETE API
    // ==========================================================

    try {
      final apiClient = context.read<ApiClient>();

      final scheduleService = ScheduleService(apiClient: apiClient);

      await scheduleService.deleteSchedule(scheduleId: schedule.id);

      if (!mounted) {
        return;
      }

      // ========================================================
      // 삭제 후 일정 새로 조회
      // ========================================================

      setState(() {
        _scheduleFuture = _loadSchedules();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정이 삭제되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('[SCHEDULE DELETE] $error');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일정을 삭제하지 못했습니다.')));
    }
  }

  // ============================================================
  // STEP 4. 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '일정',
      selectedIndex: 8,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // 일정 Page Tabs
              // ==================================================
              ScheduleSectionTabs(
                selectedSection: _selectedSection,
                onChanged: (section) {
                  if (_selectedSection == section) {
                    return;
                  }

                  setState(() {
                    _selectedSection = section;
                  });
                },
              ),

              const SizedBox(height: 8),

              Expanded(child: _buildSelectedSection()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 선택된 일정 Section
  // ============================================================

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case ScheduleSection.mySchedule:
        return _buildMyScheduleTab();

      case ScheduleSection.leaveRequest:
        return _buildLeaveRequestTab();

      case ScheduleSection.onCallStatus:
        return _buildOnCallTab();
    }
  }

  // ============================================================
  // 내 스케줄 Tab
  // ============================================================

  Widget _buildMyScheduleTab() {
    return FutureBuilder<List<StaffSchedule>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ScheduleError(onRetry: _reload);
        }

        final schedules =
            snapshot.data?.where((schedule) => schedule.isActive).toList() ??
            <StaffSchedule>[];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // 월간 Schedule
            // ==================================================
            Expanded(
              flex: 7,
              child: ScheduleCalendarPanel(
                focusedMonth: _focusedMonth,
                selectedDate: _selectedDate,
                schedules: schedules,
                scheduleColor: _scheduleColor,
                onPreviousMonth: _previousMonth,
                onNextMonth: _nextMonth,
                onToday: _goToday,
                onCreateSchedule: _openCreateScheduleDialog,
                onDateSelected: _selectDate,
              ),
            ),

            const SizedBox(width: 16),

            // ==================================================
            // 선택 날짜 일정
            // ==================================================
            Expanded(
              flex: 3,
              child: ScheduleDetailPanel(
                selectedDate: _selectedDate,
                schedules: _schedulesForDate(schedules, _selectedDate),
                scheduleColor: _scheduleColor,
                onEdit: _openEditScheduleDialog,
                onDelete: _deleteSchedule,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 휴무 신청 Dialog
  // 현재 API 연결 전
  // ============================================================

  Future<void> _openLeaveRequestDialog() async {
    final result = await showDialog<LeaveRequestFormResult>(
      context: context,
      builder: (dialogContext) {
        return const LeaveRequestFormDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    // ==========================================================
    // TODO:
    // 휴무 신청 API 연결 예정
    // ==========================================================

    debugPrint(
      '[LEAVE REQUEST] '
      'type=${result.leaveType}, '
      'startDate=${result.startDate}, '
      'endDate=${result.endDate}, '
      'reason=${result.reason}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('휴무 신청 내용을 확인했습니다. 현재는 API 연결 전입니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // 휴무 신청 Tab
  // 반드시 _openLeaveRequestDialog 밖에 있어야 함
  // ============================================================

  Widget _buildLeaveRequestTab() {
    return LeaveRequestPanel(
      // TODO:
      // 실제 승인 권한 API 연결 예정
      canApproveLeave: false,

      onCreateRequest: _openLeaveRequestDialog,
    );
  }

  // ============================================================
  // 당직 현황 Tab
  // ============================================================

  Widget _buildOnCallTab() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nightlight_outlined, size: 38, color: AppColors.warning),

            SizedBox(height: 12),

            Text(
              '당직 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 6),

            Text(
              '진료과별 당직 의료진 조회 기능을 준비 중입니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 8. 날짜별 일정 필터
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
  // STEP 9. 일정 색상
  // ============================================================

  Color _scheduleColor(StaffSchedule schedule) {
    // ==========================================================
    // 개인 일정
    // 공식 근무와 구분되는 Purple Accent
    // ==========================================================

    if (schedule.scheduleType == 'PERSONAL') {
      return const Color(0xFF7C6BC4);
    }

    // ==========================================================
    // 서버에서 전달된 Color
    // ==========================================================

    final serverColor = schedule.color;

    if (serverColor != null &&
        serverColor.startsWith('#') &&
        serverColor.length == 7) {
      try {
        final hex = serverColor.substring(1);

        return Color(0xFF000000 | int.parse(hex, radix: 16));
      } catch (_) {
        // 서버 Color Parsing 실패 시 아래 Type Color 사용
      }
    }

    // ==========================================================
    // 일정 Type별 기본 Color
    // ==========================================================

    switch (schedule.scheduleType) {
      case 'CLINICAL':
        return AppColors.primaryBlue;

      case 'ON_CALL':
        return AppColors.warning;

      case 'OFF':
        return AppColors.textSecondary;

      default:
        return AppColors.secondaryBlue;
    }
  }

  // ============================================================
  // _StaffSchedulePageState 종료
  // ============================================================
}

// ============================================================
// STEP 16. Error
// ============================================================

class _ScheduleError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ScheduleError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: AppColors.danger,
          ),

          const SizedBox(height: 10),

          const Text(
            '일정을 불러오지 못했습니다.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
