import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'appointment_ui_model.dart';
import 'widgets/appointment_detail_panel.dart';
import 'widgets/appointment_list_panel.dart';
import 'widgets/appointment_status_filter.dart';

// ============================================================
// STEP 1. Appointments Page
// 실제 Backend 구조 기반 Mock UI
// ============================================================

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  // ============================================================
  // STEP 2. Mock 예약 Data
  // 실제 /api/staff/reservations/ 응답 구조 기준
  // ============================================================

  late List<AppointmentUiModel> _appointments;

  AppointmentStatusFilter _selectedFilter = AppointmentStatusFilter.all;

  int? _selectedAppointmentId;

  // ============================================================
  // STEP 3. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _appointments = _buildMockAppointments();

    if (_appointments.isNotEmpty) {
      _selectedAppointmentId = _appointments.first.id;
    }
  }

  // ============================================================
  // STEP 4. Filtered Appointments
  // ============================================================

  List<AppointmentUiModel> get _filteredAppointments {
    switch (_selectedFilter) {
      case AppointmentStatusFilter.all:
        return _appointments;

      case AppointmentStatusFilter.requested:
        return _appointments
            .where((item) => item.status == AppointmentStatus.requested)
            .toList();

      case AppointmentStatusFilter.accepted:
        return _appointments
            .where((item) => item.status == AppointmentStatus.accepted)
            .toList();

      case AppointmentStatusFilter.canceled:
        return _appointments
            .where((item) => item.status == AppointmentStatus.canceled)
            .toList();
    }
  }

  // ============================================================
  // STEP 5. 선택된 예약
  // ============================================================

  AppointmentUiModel? get _selectedAppointment {
    if (_selectedAppointmentId == null) {
      return null;
    }

    for (final appointment in _appointments) {
      if (appointment.id == _selectedAppointmentId) {
        return appointment;
      }
    }

    return null;
  }

  // ============================================================
  // STEP 6. 예약 선택
  // ============================================================

  void _selectAppointment(AppointmentUiModel appointment) {
    setState(() {
      _selectedAppointmentId = appointment.id;
    });
  }

  // ============================================================
  // STEP 7. Filter 변경
  // ============================================================

  void _changeFilter(AppointmentStatusFilter filter) {
    setState(() {
      _selectedFilter = filter;

      final filtered = _getFilteredAppointments(filter);

      if (filtered.isEmpty) {
        _selectedAppointmentId = null;
      } else {
        final currentExists = filtered.any(
          (item) => item.id == _selectedAppointmentId,
        );

        if (!currentExists) {
          _selectedAppointmentId = filtered.first.id;
        }
      }
    });
  }

  List<AppointmentUiModel> _getFilteredAppointments(
    AppointmentStatusFilter filter,
  ) {
    switch (filter) {
      case AppointmentStatusFilter.all:
        return _appointments;

      case AppointmentStatusFilter.requested:
        return _appointments
            .where((item) => item.status == AppointmentStatus.requested)
            .toList();

      case AppointmentStatusFilter.accepted:
        return _appointments
            .where((item) => item.status == AppointmentStatus.accepted)
            .toList();

      case AppointmentStatusFilter.canceled:
        return _appointments
            .where((item) => item.status == AppointmentStatus.canceled)
            .toList();
    }
  }

  // ============================================================
  // STEP 8. Mock 예약 승인
  // 현재는 UI 확인용
  // 추후 POST /staff/reservations/{id}/accept/ 연결
  // ============================================================

  void _acceptAppointment(AppointmentUiModel appointment) {
    final index = _appointments.indexWhere((item) => item.id == appointment.id);

    if (index < 0) {
      return;
    }

    setState(() {
      _appointments[index] = appointment.copyWith(
        status: AppointmentStatus.accepted,
        acceptedAt: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('예약 승인 UI가 반영되었습니다. 실제 API는 아직 연결하지 않았습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // STEP 9. Count
  // ============================================================

  int _countStatus(AppointmentStatus status) {
    return _appointments.where((item) => item.status == status).length;
  }

  // ============================================================
  // STEP 10. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ==========================================================
    // RBAC
    // 의사: appointmentView
    // 간호사: appointmentView + appointmentManage
    // ==========================================================

    final canManage = auth.hasPermission(AppPermission.appointmentManage);

    return AppShell(
      pageTitle: '예약',
      selectedIndex: 2,
      body: Material(
        color: AppColors.background,
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // Filter
              // ==================================================
              AppointmentStatusFilterBar(
                selectedFilter: _selectedFilter,
                totalCount: _appointments.length,
                requestedCount: _countStatus(AppointmentStatus.requested),
                acceptedCount: _countStatus(AppointmentStatus.accepted),
                canceledCount: _countStatus(AppointmentStatus.canceled),
                canManage: canManage,
                onChanged: _changeFilter,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // Main Content
              // ==================================================
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==============================================
                    // 예약 목록
                    // ==============================================
                    Expanded(
                      flex: 4,
                      child: AppointmentListPanel(
                        appointments: _filteredAppointments,
                        selectedAppointmentId: _selectedAppointmentId,
                        onAppointmentSelected: _selectAppointment,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ==============================================
                    // 예약 상세
                    // ==============================================
                    Expanded(
                      flex: 6,
                      child: AppointmentDetailPanel(
                        appointment: _selectedAppointment,
                        canManage: canManage,
                        onAccept: _acceptAppointment,
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

  // ============================================================
  // STEP 11. Mock Data
  // Swagger 실제 응답을 기반으로 구성
  // ============================================================

  List<AppointmentUiModel> _buildMockAppointments() {
    return [
      AppointmentUiModel(
        id: 8,
        applicantName: '김유리',
        applicantBirthDate: '1972-01-01',
        applicantContact: '+821012345678',
        applicantGender: null,
        reservedAt: DateTime(2026, 9, 14, 8, 30),
        status: AppointmentStatus.requested,
        acceptedAt: null,
        createdAt: DateTime(2026, 9, 12, 12, 28),
        updatedAt: DateTime(2026, 9, 12, 12, 28),
        canceledAt: null,
        cancelReason: null,
        patientAccount: 6,
        patient: null,
        doctor: 3,
        identityVerification: 18,
        department: 1,
        acceptedBy: null,
        canceledBy: null,
      ),

      AppointmentUiModel(
        id: 10,
        applicantName: '123',
        applicantBirthDate: '1995-04-20',
        applicantContact: '+821012345678',
        applicantGender: null,
        reservedAt: DateTime(2026, 9, 14, 9, 0),
        status: AppointmentStatus.requested,
        acceptedAt: null,
        createdAt: DateTime(2026, 9, 12, 15, 44),
        updatedAt: DateTime(2026, 9, 12, 15, 44),
        canceledAt: null,
        cancelReason: null,
        patientAccount: 6,
        patient: null,
        doctor: 3,
        identityVerification: 20,
        department: 1,
        acceptedBy: null,
        canceledBy: null,
      ),

      AppointmentUiModel(
        id: 9,
        applicantName: '123',
        applicantBirthDate: '1995-01-01',
        applicantContact: '+821012345678',
        applicantGender: null,
        reservedAt: DateTime(2026, 9, 14, 9, 30),
        status: AppointmentStatus.requested,
        acceptedAt: null,
        createdAt: DateTime(2026, 9, 12, 14, 4),
        updatedAt: DateTime(2026, 9, 12, 14, 4),
        canceledAt: null,
        cancelReason: null,
        patientAccount: 6,
        patient: null,
        doctor: 3,
        identityVerification: 19,
        department: 1,
        acceptedBy: null,
        canceledBy: null,
      ),

      AppointmentUiModel(
        id: 11,
        applicantName: '김유리',
        applicantBirthDate: '1999-01-01',
        applicantContact: '+821012345678',
        applicantGender: null,
        reservedAt: DateTime(2026, 9, 14, 11, 0),
        status: AppointmentStatus.requested,
        acceptedAt: null,
        createdAt: DateTime(2026, 9, 12, 17, 14),
        updatedAt: DateTime(2026, 9, 12, 17, 14),
        canceledAt: null,
        cancelReason: null,
        patientAccount: 6,
        patient: null,
        doctor: 3,
        identityVerification: 21,
        department: 1,
        acceptedBy: null,
        canceledBy: null,
      ),

      AppointmentUiModel(
        id: 2,
        applicantName: '테스트환자',
        applicantBirthDate: '1990-01-01',
        applicantContact: '010-1111-2222',
        applicantGender: 'FEMALE',
        reservedAt: DateTime(2026, 8, 26, 22, 26),
        status: AppointmentStatus.accepted,
        acceptedAt: DateTime(2026, 8, 24, 22, 30),
        createdAt: DateTime(2026, 8, 24, 22, 26),
        updatedAt: DateTime(2026, 8, 24, 22, 30),
        canceledAt: null,
        cancelReason: null,
        patientAccount: 1,
        patient: 2,
        doctor: null,
        identityVerification: null,
        department: 1,
        acceptedBy: 2,
        canceledBy: null,
      ),

      AppointmentUiModel(
        id: 4,
        applicantName: '김유리',
        applicantBirthDate: '1995-12-20',
        applicantContact: '01012345678',
        applicantGender: null,
        reservedAt: DateTime(2026, 9, 24, 10, 30),
        status: AppointmentStatus.canceled,
        acceptedAt: null,
        createdAt: DateTime(2026, 9, 10, 16, 10),
        updatedAt: DateTime(2026, 9, 12, 13, 2),
        canceledAt: DateTime(2026, 9, 12, 13, 2),
        cancelReason: null,
        patientAccount: 6,
        patient: null,
        doctor: 3,
        identityVerification: 13,
        department: 1,
        acceptedBy: null,
        canceledBy: null,
      ),
    ];
  }
}
