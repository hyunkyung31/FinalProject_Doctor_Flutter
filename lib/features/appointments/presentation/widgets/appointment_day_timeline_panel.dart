import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../patients/presentation/widgets/patient_detail_tabs.dart';
import '../appointment_ui_model.dart';

class AppointmentDayTimelinePanel extends StatelessWidget {
  final List<AppointmentUiModel> appointments;
  final DateTime selectedDate;
  final Map<int, PatientUiModel> patientMap;
  final int? selectedAppointmentId;
  final ValueChanged<AppointmentUiModel> onAppointmentSelected;
  final bool canManage;
  final ValueChanged<AppointmentUiModel> onAccept;
  final Widget? filterBar;

  const AppointmentDayTimelinePanel({
    super.key,
    required this.appointments,
    required this.selectedDate,
    required this.patientMap,
    required this.selectedAppointmentId,
    required this.onAppointmentSelected,
    required this.canManage,
    required this.onAccept,
    this.filterBar,
  });

  static const int _openMinute = 8 * 60 + 30;
  static const int _closeMinute = 18 * 60;

  List<AppointmentUiModel> get _dailyAppointments {
    final result = appointments.where((appointment) {
      final reservedAt = appointment.reservedAt.toLocal();

      return reservedAt.year == selectedDate.year &&
          reservedAt.month == selectedDate.month &&
          reservedAt.day == selectedDate.day;
    }).toList();

    result.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    return result;
  }

  List<AppointmentUiModel> get _inHoursAppointments {
    return _dailyAppointments.where((appointment) {
      final local = appointment.reservedAt.toLocal();

      final minute = local.hour * 60 + local.minute;

      return minute >= _openMinute && minute < _closeMinute;
    }).toList();
  }

  AppointmentUiModel? _findSelected(List<AppointmentUiModel> items) {
    if (selectedAppointmentId == null) {
      return null;
    }

    for (final item in items) {
      if (item.id == selectedAppointmentId) {
        return item;
      }
    }

    return null;
  }

  List<AppointmentUiModel> _slotAppointments(
    List<AppointmentUiModel> items,
    int startMinute,
  ) {
    return items.where((appointment) {
      final local = appointment.reservedAt.toLocal();

      final minute = local.hour * 60 + local.minute;

      return minute >= startMinute && minute < startMinute + 30;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dailyAppointments = _dailyAppointments;

    final inHoursAppointments = _inHoursAppointments;

    final selected = _findSelected(dailyAppointments);

    final slots = <int>[
      for (var minute = _openMinute; minute < _closeMinute; minute += 30)
        minute,
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedDate.month}월 '
                        '${selectedDate.day}일 예약 일정',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '진료시간 08:30 ~ 18:00 · 30분 단위',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${dailyAppointments.length}건',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (filterBar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: filterBar!,
            ),

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: dailyAppointments.isEmpty
                ? const _EmptyTimeline()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    children: [
                      ...slots.map((slotMinute) {
                        final slotAppointments = _slotAppointments(
                          inHoursAppointments,
                          slotMinute,
                        );

                        final shouldAutoScroll =
                            dailyAppointments.length == 1 &&
                            slotAppointments.isNotEmpty;

                        final triggerKey =
                            '${selectedDate.year}-'
                            '${selectedDate.month}-'
                            '${selectedDate.day}-'
                            '${dailyAppointments.length == 1 ? dailyAppointments.first.id : 0}';

                        return _AutoScrollTarget(
                          active: shouldAutoScroll,
                          triggerKey: triggerKey,
                          child: _TimeSlotRow(
                            minute: slotMinute,
                            appointments: slotAppointments,
                            patientMap: patientMap,
                            selectedAppointmentId: selectedAppointmentId,
                            onAppointmentSelected: onAppointmentSelected,
                          ),
                        );
                      }),

                      const _ClosingTimeRow(),
                    ],
                  ),
          ),

          if (selected != null)
            _SelectedAppointmentSummary(
              appointment: selected,
              patient: selected.patient == null
                  ? null
                  : patientMap[selected.patient],
              canManage: canManage,
              onAccept: () {
                onAccept(selected);
              },
            ),
        ],
      ),
    );
  }
}

class _AutoScrollTarget extends StatefulWidget {
  final bool active;
  final Object triggerKey;
  final Widget child;

  const _AutoScrollTarget({
    required this.active,
    required this.triggerKey,
    required this.child,
  });

  @override
  State<_AutoScrollTarget> createState() => _AutoScrollTargetState();
}

class _AutoScrollTargetState extends State<_AutoScrollTarget> {
  @override
  void initState() {
    super.initState();

    if (widget.active) {
      _scheduleScroll();
    }
  }

  @override
  void didUpdateWidget(covariant _AutoScrollTarget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active &&
        (!oldWidget.active || oldWidget.triggerKey != widget.triggerKey)) {
      _scheduleScroll();
    }
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TimeSlotRow extends StatelessWidget {
  final int minute;
  final List<AppointmentUiModel> appointments;
  final Map<int, PatientUiModel> patientMap;
  final int? selectedAppointmentId;
  final ValueChanged<AppointmentUiModel> onAppointmentSelected;

  const _TimeSlotRow({
    required this.minute,
    required this.appointments,
    required this.patientMap,
    required this.selectedAppointmentId,
    required this.onAppointmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasAppointments = appointments.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 9, right: 7),
              child: Text(
                _formatMinute(minute),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: hasAppointments
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: hasAppointments
                      ? context.appTextPrimary
                      : context.appTextSecondary,
                ),
              ),
            ),
          ),

          Container(width: 1, color: context.appBorder),

          const SizedBox(width: 6),

          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: hasAppointments
                  ? Column(
                      children: [
                        for (
                          var index = 0;
                          index < appointments.length;
                          index++
                        ) ...[
                          _AppointmentTile(
                            appointment: appointments[index],
                            patient: appointments[index].patient == null
                                ? null
                                : patientMap[appointments[index].patient],
                            selected:
                                appointments[index].id == selectedAppointmentId,
                            onTap: () {
                              onAppointmentSelected(appointments[index]);
                            },
                          ),

                          if (index < appointments.length - 1)
                            const SizedBox(height: 4),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingTimeRow extends StatelessWidget {
  const _ClosingTimeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Padding(
            padding: EdgeInsets.only(right: 7),
            child: Text(
              '18:00',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ),
        ),

        Container(width: 1, height: 26, color: context.appBorder),

        const SizedBox(width: 10),

        Expanded(child: Divider(height: 1, color: context.appBorder)),
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentUiModel appointment;
  final PatientUiModel? patient;
  final bool selected;
  final VoidCallback onTap;

  const _AppointmentTile({
    required this.appointment,
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = patient?.name ?? appointment.applicantName;

    final displayAge = patient?.age ?? appointment.age;

    final recordNo = patient?.medicalRecordNo;

    final recordText = recordNo != null && recordNo.isNotEmpty
        ? ' ($recordNo)'
        : '';

    final genderAge = _formatGenderAge(
      patient?.gender ?? appointment.genderText,
      displayAge,
    );

    final displayText =
        '$displayName$recordText'
        '${genderAge.isEmpty ? '' : '  $genderAge'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _statusBackground(appointment.status),
            borderRadius: BorderRadius.circular(8),

            // 선택해도 강한 파란 테두리를 두르지 않고
            // 약한 테두리 + 그림자로만 강조
            border: Border.all(
              color: selected
                  ? AppColors.primaryBlue.withValues(alpha: 0.45)
                  : context.appBorder,
              width: selected ? 1.2 : 1,
            ),

            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.10),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (selected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 8),
              ],

              Expanded(
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              _StatusBadge(status: appointment.status),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusBackground(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.requested:
      return AppColors.warningBackground;

    case AppointmentStatus.accepted:
      return AppColors.successBackground;

    case AppointmentStatus.canceled:
      return AppColors.dangerBackground;
  }
}

class _SelectedAppointmentSummary extends StatelessWidget {
  final AppointmentUiModel appointment;
  final PatientUiModel? patient;
  final bool canManage;
  final VoidCallback onAccept;

  const _SelectedAppointmentSummary({
    required this.appointment,
    required this.patient,
    required this.canManage,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = patient?.name ?? appointment.applicantName;

    final displayAge = patient?.age ?? appointment.age;

    final displayGender = patient?.gender ?? appointment.genderText;

    final contact = patient?.phone.isNotEmpty == true
        ? patient!.phone
        : appointment.applicantContact;

    final recordNo = patient?.medicalRecordNo;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 17,
              color: context.appBrand,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayAge == null
                            ? displayName
                            : '$displayName · '
                                  '$displayAge세 · '
                                  '$displayGender',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _StatusBadge(status: appointment.status),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '예약 '
                  '${_formatTime(appointment.reservedAt.toLocal())}'
                  '  ·  ${_formatContact(contact)}'
                  '${recordNo != null && recordNo.isNotEmpty ? '  ·  $recordNo' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (canManage &&
              appointment.status == AppointmentStatus.requested) ...[
            const SizedBox(width: 14),

            FilledButton.icon(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(104, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 15),
              label: const Text(
                '예약 승인',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 34,
            color: context.appTextDisabled,
          ),
          SizedBox(height: 9),
          Text(
            '이 날짜에는 예약이 없습니다.',
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

String _formatMinute(int minute) {
  final hour = minute ~/ 60;
  final min = minute % 60;

  return '${hour.toString().padLeft(2, '0')}:'
      '${min.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String? _shortGender(String value) {
  switch (value.trim().toUpperCase()) {
    case '여':
    case 'F':
    case 'FEMALE':
      return 'F';

    case '남':
    case 'M':
    case 'MALE':
      return 'M';

    default:
      return null;
  }
}

String _formatGenderAge(String gender, int? age) {
  final shortGender = _shortGender(gender);

  if (shortGender != null && age != null) {
    return '$shortGender/$age세';
  }

  if (age != null) {
    return '$age세';
  }

  return shortGender ?? '';
}

String _formatContact(String value) {
  final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (numbers.startsWith('82') && numbers.length >= 11) {
    final local = '0${numbers.substring(2)}';

    if (local.length == 11) {
      return '${local.substring(0, 3)}-'
          '${local.substring(3, 7)}-'
          '${local.substring(7)}';
    }
  }

  if (numbers.length == 11) {
    return '${numbers.substring(0, 3)}-'
        '${numbers.substring(3, 7)}-'
        '${numbers.substring(7)}';
  }

  return value;
}
