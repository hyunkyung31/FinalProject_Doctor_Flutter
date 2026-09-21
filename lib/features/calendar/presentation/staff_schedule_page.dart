import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/models/staff_schedule.dart';
import '../data/services/schedule_service.dart';
import '../data/models/attendance_request.dart';
import '../data/services/attendance_request_service.dart';

import 'widgets/schedule_form_dialog.dart';
import 'widgets/schedule_detail_panel.dart';
import 'widgets/schedule_calendar_panel.dart';
import 'widgets/schedule_section_tabs.dart';
import 'widgets/leave_request_panel.dart';
import 'widgets/leave_request_form_dialog.dart';
import 'widgets/on_call_status_panel.dart';

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

  int _leaveRequestRefreshVersion = 0;

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
      selectedIndex: 7,
      body: Material(
        color: context.appBackground,
        child: Container(
          color: context.appBackground,
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
        return const OnCallStatusPanel();
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
  // 휴무 신청 Dialog + API 등록
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
    // Flutter LeaveType → Backend AttendanceType
    // ==========================================================

    final AttendanceType attendanceType;

    switch (result.leaveType) {
      case LeaveType.annual:
        attendanceType = AttendanceType.annualLeave;

      case LeaveType.morningHalf:
        attendanceType = AttendanceType.halfDayAm;

      case LeaveType.afternoonHalf:
        attendanceType = AttendanceType.halfDayPm;

      case LeaveType.hourly:
        attendanceType = AttendanceType.hourlyLeave;

      case LeaveType.sickLeave:
        attendanceType = AttendanceType.sickLeave;

      case LeaveType.officialLeave:
        attendanceType = AttendanceType.officialLeave;

      case LeaveType.businessTrip:
        attendanceType = AttendanceType.businessTrip;

      case LeaveType.education:
        attendanceType = AttendanceType.education;
    }

    final isAllDay =
        result.leaveType != LeaveType.morningHalf &&
        result.leaveType != LeaveType.afternoonHalf &&
        result.leaveType != LeaveType.hourly;

    try {
      final apiClient = context.read<ApiClient>();

      final service = AttendanceRequestService(apiClient: apiClient);

      final createdRequest = await service.createRequest(
        attendanceType: attendanceType,
        startDate: result.startDate,
        endDate: result.endDate,
        isAllDay: isAllDay,
        startTime: result.startTime,
        endTime: result.endTime,
        memo: null,
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        '[LEAVE REQUEST] 등록 성공 '
        'id=${createdRequest.id}, '
        'type=${createdRequest.attendanceType.apiValue}, '
        'status=${createdRequest.status}',
      );

      // ========================================================
      // 휴무 신청 목록 새로 조회
      // LeaveRequestPanel을 새로 생성
      // ========================================================

      setState(() {
        _leaveRequestRefreshVersion++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴무 신청이 등록되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      debugPrint(
        '[LEAVE REQUEST] 등록 실패 '
        'status=$statusCode, '
        'data=$responseData',
      );

      if (!mounted) {
        return;
      }

      String message = '휴무 신청을 등록하지 못했습니다.';

      if (responseData is Map) {
        final detail = responseData['detail'];

        if (detail != null && detail.toString().trim().isNotEmpty) {
          message = detail.toString();
        } else if (responseData.isNotEmpty) {
          message = responseData.values.first.toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  // ============================================================
  // 휴무 신청 Tab
  // ============================================================

  Widget _buildLeaveRequestTab() {
    final auth = context.watch<AuthProvider>();

    debugPrint(
      '[LEAVE PERMISSION] '
      'user=${auth.userName}, '
      'isDepartmentHead=${auth.isDepartmentHead}',
    );

    return LeaveRequestPanel(
      key: ValueKey(_leaveRequestRefreshVersion),
      canApproveLeave: auth.isDepartmentHead,
      onCreateRequest: _openLeaveRequestDialog,
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
        return context.appTextSecondary;

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

          Text(
            '일정을 불러오지 못했습니다.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
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
