import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../patients/presentation/widgets/patient_detail_tabs.dart';
import '../appointment_ui_model.dart';

// ============================================================
// STEP 1. Appointment List Panel
// ============================================================

class AppointmentListPanel extends StatefulWidget {
  final List<AppointmentUiModel> appointments;
  final int? selectedAppointmentId;
  final DateTime selectedDate;
  final Map<int, PatientUiModel> patientMap;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<AppointmentUiModel> onAppointmentSelected;

  const AppointmentListPanel({
    super.key,
    required this.appointments,
    required this.selectedAppointmentId,
    required this.selectedDate,
    required this.patientMap,
    required this.onDateChanged,
    required this.onAppointmentSelected,
  });

  @override
  State<AppointmentListPanel> createState() => _AppointmentListPanelState();
}

class _AppointmentListPanelState extends State<AppointmentListPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

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
  void didUpdateWidget(covariant AppointmentListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _focusedMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppointmentUiModel> get _filteredAppointments {
    final query = _searchText.trim().toLowerCase();

    final result = widget.appointments.where((appointment) {
      final reservedDate = appointment.reservedAt.toLocal();

      final sameDate =
          reservedDate.year == widget.selectedDate.year &&
          reservedDate.month == widget.selectedDate.month &&
          reservedDate.day == widget.selectedDate.day;

      if (!sameDate) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return appointment.applicantName.toLowerCase().contains(query) ||
          appointment.applicantContact.toLowerCase().contains(query) ||
          appointment.applicantBirthDate.contains(query) ||
          appointment.id.toString().contains(query);
    }).toList();

    result.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    return result;
  }

  int _appointmentCountForDate(DateTime date) {
    return widget.appointments.where((appointment) {
      final reservedDate = appointment.reservedAt.toLocal();

      return reservedDate.year == date.year &&
          reservedDate.month == date.month &&
          reservedDate.day == date.day;
    }).length;
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

  Widget _buildCalendar() {
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _moveMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                visualDensity: VisualDensity.compact,
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
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarCellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.6,
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

              final count = _appointmentCountForDate(date);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onDateChanged(date);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
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
                          const SizedBox(height: 1),
                          Text(
                            '$count건',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.88)
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
      ],
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _filteredAppointments;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '예약 일정',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
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

          _buildCalendar(),

          const SizedBox(height: 10),

          Divider(height: 1, color: context.appBorder),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.selectedDate.month}월 '
                    '${widget.selectedDate.day}일 예약',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appointments.length}건',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.appTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '신청자명 · 연락처 · 예약번호 검색',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: context.appTextDisabled,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: context.appTextSecondary,
                  ),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _searchText = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 15),
                        ),
                  filled: true,
                  fillColor: context.appBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: context.appBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: appointments.isEmpty
                ? const _EmptyAppointments()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];

                      return _AppointmentListItem(
                        appointment: appointment,
                        patient: appointment.patient == null
                            ? null
                            : widget.patientMap[appointment.patient],
                        selected:
                            widget.selectedAppointmentId == appointment.id,
                        onTap: () {
                          widget.onAppointmentSelected(appointment);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Appointment Item
// ============================================================

class _AppointmentListItem extends StatelessWidget {
  final AppointmentUiModel appointment;
  final PatientUiModel? patient;
  final bool selected;
  final VoidCallback onTap;

  const _AppointmentListItem({
    required this.appointment,
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = patient?.name ?? appointment.applicantName;

    final displayAge = patient?.age ?? appointment.age;

    final displayBirthDate =
        patient?.birthDate ?? appointment.applicantBirthDate;

    final displayGender = patient?.gender ?? appointment.genderText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? context.appSurfaceSoft : context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primaryBlue : context.appBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // 시간
              // ==================================================
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatTime(appointment.reservedAt.toLocal()),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Container(width: 1, height: 44, color: context.appBorder),

              const SizedBox(width: 11),

              // ==================================================
              // 신청자 정보
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayAge == null
                                ? displayName
                                : '$displayName · $displayAge세',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _StatusBadge(status: appointment.status),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$displayBirthDate · $displayGender',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.appTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      appointment.patient == null
                          ? '환자 정보 미연결'
                          : '환자 #${appointment.patient} 연결됨',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: appointment.patient == null
                            ? context.appTextSecondary
                            : AppColors.success,
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

// ============================================================
// STEP 6. Status Badge
// ============================================================

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color foreground;
    Color background;

    switch (status) {
      case AppointmentStatus.requested:
        foreground = AppColors.warning;
        background = AppColors.warningBackground;
        break;

      case AppointmentStatus.accepted:
        foreground = AppColors.success;
        background = AppColors.successBackground;
        break;

      case AppointmentStatus.canceled:
        foreground = AppColors.danger;
        background = AppColors.dangerBackground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 8.8,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Empty
// ============================================================

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 34,
            color: context.appTextDisabled,
          ),

          SizedBox(height: 9),

          Text(
            '조건에 맞는 예약이 없습니다.',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Format
// ============================================================

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
