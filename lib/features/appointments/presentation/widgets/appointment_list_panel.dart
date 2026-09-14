import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../appointment_ui_model.dart';

// ============================================================
// STEP 1. Appointment List Panel
// ============================================================

class AppointmentListPanel extends StatefulWidget {
  final List<AppointmentUiModel> appointments;

  final int? selectedAppointmentId;

  final ValueChanged<AppointmentUiModel> onAppointmentSelected;

  const AppointmentListPanel({
    super.key,
    required this.appointments,
    required this.selectedAppointmentId,
    required this.onAppointmentSelected,
  });

  @override
  State<AppointmentListPanel> createState() => _AppointmentListPanelState();
}

class _AppointmentListPanelState extends State<AppointmentListPanel> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  // ============================================================
  // STEP 2. Dispose
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP 3. 검색된 예약
  // ============================================================

  List<AppointmentUiModel> get _filteredAppointments {
    final query = _searchText.trim().toLowerCase();

    final result = widget.appointments.where((appointment) {
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

  // ============================================================
  // STEP 4. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final appointments = _filteredAppointments;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '예약 목록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appointments.length}건',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Search
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '신청자명 · 연락처 · 예약번호 검색',
                  hintStyle: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
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
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: AppColors.border),
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

          const SizedBox(height: 12),

          const Divider(height: 1, color: AppColors.border),

          // ======================================================
          // List
          // ======================================================
          Expanded(
            child: appointments.isEmpty
                ? const _EmptyAppointments()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];

                      return _AppointmentListItem(
                        appointment: appointment,
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
  final bool selected;

  final VoidCallback onTap;

  const _AppointmentListItem({
    required this.appointment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final age = appointment.age;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.border,
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
                child: Column(
                  children: [
                    Text(
                      _formatTime(appointment.reservedAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatShortDate(appointment.reservedAt),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(width: 1, height: 52, color: AppColors.border),

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
                            age == null
                                ? appointment.applicantName
                                : '${appointment.applicantName} · $age세',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _StatusBadge(status: appointment.status),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${appointment.applicantBirthDate} · ${appointment.genderText}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
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
                            ? AppColors.textSecondary
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 34,
            color: AppColors.textDisabled,
          ),

          SizedBox(height: 9),

          Text(
            '조건에 맞는 예약이 없습니다.',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}
