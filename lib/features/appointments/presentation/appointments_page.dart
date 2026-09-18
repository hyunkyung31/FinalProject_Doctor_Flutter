import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../patients/data/services/patient_service.dart';
import '../../patients/presentation/widgets/patient_detail_tabs.dart';

import 'appointment_ui_model.dart';
import '../data/services/appointment_service.dart';
import 'widgets/appointment_calendar_panel.dart';
import 'widgets/appointment_day_timeline_panel.dart';
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
  // 예약 Data
  // 실제 /api/staff/reservations/ 응답 구조 기준
  // ============================================================

  List<AppointmentUiModel> _appointments = [];

  Map<int, PatientUiModel> _patientMap = {};

  AppointmentStatusFilter _selectedFilter = AppointmentStatusFilter.all;

  int? _selectedAppointmentId;

  DateTime _selectedDate = DateTime.now();

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

      final patientService = PatientService(
        apiClient: auth.authService.apiClient,
      );

      // 예약과 실제 환자 목록 조회를 동시에 시작
      final appointmentsFuture = appointmentService.fetchAppointments();
      final patientsFuture = _fetchAllPatients(patientService);

      final appointments = await appointmentsFuture;

      appointments.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

      if (!mounted) {
        return;
      }

      // 예약 데이터는 먼저 화면에 표시
      setState(() {
        _appointments = appointments;

        final filtered = _getFilteredAppointments(_selectedFilter);

        if (filtered.isEmpty) {
          _selectedAppointmentId = null;
          return;
        }

        _selectedDate = _resolveDateForAppointments(
          _appointments,
          _selectedDate,
        );

        final appointmentsOnDate = _appointmentsOnDate(
          _appointments,
          _selectedDate,
        );

        final filteredAppointments = _filterAppointments(
          appointmentsOnDate,
          _selectedFilter,
        );

        _selectedAppointmentId = _resolveSelectedAppointmentId(
          filteredAppointments,
        );
      });

      debugPrint(
        '[APPOINTMENTS] 예약 목록 조회 완료: '
        '${appointments.length}건',
      );

      // 실제 환자 정보 연결
      try {
        final patients = await patientsFuture;

        if (!mounted) {
          return;
        }

        setState(() {
          _patientMap = {
            for (final patient in patients) patient.patientId: patient,
          };
        });

        debugPrint(
          '[APPOINTMENTS] 실제 환자 정보 연결 완료: '
          '${patients.length}명',
        );
      } catch (error) {
        debugPrint('[APPOINTMENTS] 환자 정보 조회 실패: $error');
      }
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

  Future<List<PatientUiModel>> _fetchAllPatients(
    PatientService patientService,
  ) async {
    final patients = <PatientUiModel>[];

    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final result = await patientService.fetchPatientPage(page: page);

      patients.addAll(result.patients);

      hasNext = result.hasNext;
      page++;
    }

    return patients;
  }

  // ============================================================
  // STEP 4. Filtered Appointments
  // ============================================================

  List<AppointmentUiModel> get _selectedDateAppointments {
    return _appointmentsOnDate(_appointments, _selectedDate);
  }

  List<AppointmentUiModel> get _filteredAppointments {
    return _filterAppointments(_selectedDateAppointments, _selectedFilter);
  }

  List<AppointmentUiModel> _filterAppointments(
    List<AppointmentUiModel> source,
    AppointmentStatusFilter filter,
  ) {
    switch (filter) {
      case AppointmentStatusFilter.all:
        return source;

      case AppointmentStatusFilter.requested:
        return source
            .where((item) => item.status == AppointmentStatus.requested)
            .toList();

      case AppointmentStatusFilter.accepted:
        return source
            .where((item) => item.status == AppointmentStatus.accepted)
            .toList();

      case AppointmentStatusFilter.canceled:
        return source
            .where((item) => item.status == AppointmentStatus.canceled)
            .toList();
    }
  }

  // ============================================================
  // STEP 6. 예약 선택
  // ============================================================

  void _selectAppointment(AppointmentUiModel appointment) {
    setState(() {
      _selectedAppointmentId = appointment.id;
    });
  }

  void _changeDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final appointmentsOnDate = _appointmentsOnDate(
      _appointments,
      normalizedDate,
    );

    final filteredAppointments = _filterAppointments(
      appointmentsOnDate,
      _selectedFilter,
    );

    final nextSelectedAppointmentId = _resolveSelectedAppointmentId(
      filteredAppointments,
    );

    setState(() {
      _selectedDate = normalizedDate;
      _selectedAppointmentId = nextSelectedAppointmentId;
    });

    debugPrint(
      '[APPOINTMENTS] 날짜 변경: '
      '${normalizedDate.year}-'
      '${normalizedDate.month.toString().padLeft(2, '0')}-'
      '${normalizedDate.day.toString().padLeft(2, '0')} '
      '/ count=${appointmentsOnDate.length}',
    );
  }

  List<AppointmentUiModel> _appointmentsOnDate(
    List<AppointmentUiModel> appointments,
    DateTime date,
  ) {
    return appointments.where((appointment) {
      final reservedDate = appointment.reservedAt.toLocal();

      return reservedDate.year == date.year &&
          reservedDate.month == date.month &&
          reservedDate.day == date.day;
    }).toList();
  }

  int? _resolveSelectedAppointmentId(
    List<AppointmentUiModel> appointmentsOnDate,
  ) {
    final currentId = _selectedAppointmentId;

    if (currentId != null) {
      final currentExists = appointmentsOnDate.any(
        (appointment) => appointment.id == currentId,
      );

      if (currentExists) {
        return currentId;
      }
    }

    // 해당 날짜 예약이 1건일 때만 자동 선택
    if (appointmentsOnDate.length == 1) {
      return appointmentsOnDate.single.id;
    }

    // 0건 또는 2건 이상이면 사용자가 직접 선택
    return null;
  }

  DateTime _resolveDateForAppointments(
    List<AppointmentUiModel> appointments,
    DateTime preferredDate,
  ) {
    final preferred = DateTime(
      preferredDate.year,
      preferredDate.month,
      preferredDate.day,
    );

    if (appointments.isEmpty) {
      return preferred;
    }

    final dates =
        appointments
            .map((appointment) {
              final local = appointment.reservedAt.toLocal();

              return DateTime(local.year, local.month, local.day);
            })
            .toSet()
            .toList()
          ..sort();

    if (dates.any((date) => _isSameDate(date, preferred))) {
      return preferred;
    }

    for (final date in dates) {
      if (!date.isBefore(preferred)) {
        return date;
      }
    }

    return dates.last;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============================================================
  // STEP 7. Filter 변경
  // ============================================================

  void _changeFilter(AppointmentStatusFilter filter) {
    final appointmentsOnDate = _appointmentsOnDate(
      _appointments,
      _selectedDate,
    );

    final filteredAppointments = _filterAppointments(
      appointmentsOnDate,
      filter,
    );

    setState(() {
      _selectedFilter = filter;

      _selectedAppointmentId = _resolveSelectedAppointmentId(
        filteredAppointments,
      );
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
    return _selectedDateAppointments
        .where((item) => item.status == status)
        .length;
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
        color: context.appBackground,
        child: Container(
          color: context.appBackground,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // Main Content
              // ==================================================
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: double.infinity,
                          child: AppointmentCalendarPanel(
                            appointments: _appointments,
                            selectedDate: _selectedDate,
                            onDateChanged: _changeDate,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      flex: 7,
                      child: AppointmentDayTimelinePanel(
                        appointments: _filteredAppointments,
                        selectedDate: _selectedDate,
                        patientMap: _patientMap,
                        selectedAppointmentId: _selectedAppointmentId,
                        onAppointmentSelected: _selectAppointment,
                        canManage: canManage,
                        onAccept: _acceptAppointment,
                        filterBar: AppointmentStatusFilterBar(
                          selectedFilter: _selectedFilter,
                          totalCount: _selectedDateAppointments.length,
                          requestedCount: _countStatus(
                            AppointmentStatus.requested,
                          ),
                          acceptedCount: _countStatus(
                            AppointmentStatus.accepted,
                          ),
                          canceledCount: _countStatus(
                            AppointmentStatus.canceled,
                          ),
                          canManage: canManage,
                          onChanged: _changeFilter,
                        ),
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
