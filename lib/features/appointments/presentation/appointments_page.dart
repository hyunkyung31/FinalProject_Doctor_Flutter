import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';

import 'appointment_ui_model.dart';
import '../data/services/appointment_service.dart';
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

  List<AppointmentUiModel> _appointments = [];

  AppointmentStatusFilter _selectedFilter = AppointmentStatusFilter.all;

  int? _selectedAppointmentId;

  // ============================================================
  // STEP 3. Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  // ============================================================
  // STEP 4. 실제 예약 목록 조회
  // GET /staff/reservations/
  // ============================================================

  Future<void> _loadAppointments() async {
    try {
      final auth = context.read<AuthProvider>();

      final appointmentService = AppointmentService(
        apiClient: auth.authService.apiClient,
      );

      final appointments = await appointmentService.fetchAppointments();

      // 예약 시간 기준 정렬
      appointments.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = appointments;

        if (_appointments.isEmpty) {
          _selectedAppointmentId = null;
          return;
        }

        final selectedExists = _appointments.any(
          (item) => item.id == _selectedAppointmentId,
        );

        if (!selectedExists) {
          _selectedAppointmentId = _appointments.first.id;
        }
      });

      debugPrint('[APPOINTMENTS] 예약 목록 조회 완료: ${appointments.length}건');
    } catch (error) {
      debugPrint('[APPOINTMENTS] 예약 목록 조회 실패: $error');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('예약 목록을 불러오지 못했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
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
  // STEP 8. 실제 예약 승인
  // POST /staff/reservations/{id}/accept/
  // ============================================================

  Future<void> _acceptAppointment(AppointmentUiModel appointment) async {
    // ==========================================================
    // RBAC 이중 확인
    // 간호사만 예약 승인 가능
    // ==========================================================

    final auth = context.read<AuthProvider>();

    if (!auth.hasPermission(AppPermission.appointmentManage)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('현재 계정에는 예약 승인 권한이 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    // ==========================================================
    // 승인 가능한 예약인지 확인
    // ==========================================================

    if (appointment.status != AppointmentStatus.requested) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('승인 대기 상태의 예약만 승인할 수 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    // ==========================================================
    // 담당 의사 확인
    // Backend에서 doctor_id 필수
    // ==========================================================

    final doctorId = appointment.doctor;

    if (doctorId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('담당 의사 정보가 없어 예약을 승인할 수 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    // ==========================================================
    // 실제 예약 승인 API 호출
    // ==========================================================

    try {
      final appointmentService = AppointmentService(
        apiClient: auth.authService.apiClient,
      );

      await appointmentService.acceptAppointment(
        reservationId: appointment.id,
        doctorId: doctorId,
      );

      // ========================================================
      // 승인 후 서버 데이터 다시 조회
      // ========================================================

      await _loadAppointments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('예약이 승인되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );

      debugPrint(
        '[APPOINTMENTS] 예약 승인 완료: '
        'reservationId=${appointment.id}, '
        'doctorId=$doctorId',
      );
    } catch (error) {
      debugPrint('[APPOINTMENTS] 예약 승인 실패: $error');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('예약 승인에 실패했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
    }
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
}
