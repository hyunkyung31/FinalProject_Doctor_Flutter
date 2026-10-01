import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../examinations/data/services/examination_service.dart';
import '../../examinations/presentation/examination_ui_models.dart';
import '../../patients/data/services/patient_service.dart';
import '../../patients/presentation/widgets/patient_detail_tabs.dart';

import '../data/services/dashboard_metric_service.dart';
import '../data/services/today_hub_service.dart';
import '../data/models/dashboard_overview_data.dart';
import '../data/services/dashboard_overview_service.dart';
import '../data/models/staff_todo.dart';
import '../data/services/todo_service.dart';
import '../data/models/dashboard_announcement.dart';
import '../data/services/announcement_service.dart';

import 'widgets/dashboard_metric_grid.dart';
import 'widgets/my_todo_section.dart';
import 'widgets/today_hub_card.dart';
import 'widgets/recent_patients_card.dart';
import 'widgets/received_consultations_card.dart';
import 'widgets/dashboard_work_status_panel.dart';
import 'widgets/dashboard_announcement_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<_DashboardPageData>? _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _dashboardFuture ??= _loadDashboard();
  }

  Future<_DashboardPageData> _loadDashboard() async {
    final auth = context.read<AuthProvider>();
    final apiClient = auth.authService.apiClient;

    final notificationProvider = context.read<NotificationProvider>();

    final overviewService = DashboardOverviewService(apiClient: apiClient);

    final metricService = DashboardMetricService(apiClient: apiClient);

    final examinationService = ExaminationService(apiClient: apiClient);

    final todayHubService = TodayHubService(apiClient: apiClient);

    final patientService = PatientService(apiClient: apiClient);

    final todoService = TodoService(apiClient: apiClient);

    final announcementService = AnnouncementService(apiClient: apiClient);

    // ============================================================
    // 요청 시작
    // ============================================================

    final overviewFuture = overviewService.fetchOverview(
      date: dashboardNowKst(),
    );

    final examinationOrdersFuture = examinationService.fetchExaminationOrders();

    final todayHubFuture = todayHubService.fetchToday(
      isNurse: auth.isNurse,
      doctorId: auth.currentUser?.doctorId,
    );

    final notificationFuture = notificationProvider.loadNotifications();

    final summaryFuture = metricService.fetchSummary(
      overviewFuture: overviewFuture,
    );

    final recentPatientsFuture = patientService.fetchRecentPatients(page: 1);

    final todoFuture = todoService.fetchTodos();

    final announcementsFuture = announcementService.fetchAnnouncements();

    // ============================================================
    // STEP 2. Overview
    // ============================================================

    DashboardOverviewData overview;

    try {
      overview = await overviewFuture;
    } catch (error) {
      debugPrint('[DASHBOARD] overview 조회 실패: $error');

      overview = DashboardOverviewData.empty();
    }

    // ============================================================
    // STEP 3. Examination
    // 검사 오더만 조회
    // ============================================================

    List<ExaminationOrderUiModel> examinationOrders = [];

    var examinationErrorCount = 0;

    try {
      examinationOrders = await examinationOrdersFuture;
    } catch (error) {
      examinationErrorCount += 1;

      debugPrint('[DASHBOARD] 검사 현황 조회 실패: $error');
    }

    // ============================================================
    // STEP 4. Today Hub
    // ============================================================

    TodayHubData todayHub;

    try {
      todayHub = await todayHubFuture;
    } catch (error) {
      debugPrint('[DASHBOARD] Today Hub 조회 실패: $error');

      todayHub = TodayHubData.empty;
    }

    // ============================================================
    // 최근 본 환자
    // ============================================================

    List<PatientUiModel> recentPatients = [];
    int recentPatientTotal = 0;
    bool recentPatientsLoadFailed = false;
    var recentPatientsErrorCount = 0;

    try {
      final result = await recentPatientsFuture;

      recentPatients = result.patients;
      recentPatientTotal = result.count;
    } catch (error) {
      recentPatientsLoadFailed = true;
      recentPatientsErrorCount += 1;

      debugPrint('[DASHBOARD] 최근 본 환자 조회 실패: $error');
    }

    // ============================================================
    // STEP. My Todo
    // ============================================================

    List<StaffTodo> todos = [];
    bool todosLoadFailed = false;
    var todosErrorCount = 0;

    try {
      todos = await todoFuture;
    } catch (error) {
      todosLoadFailed = true;
      todosErrorCount += 1;

      debugPrint('[DASHBOARD] To-do 목록 조회 실패: $error');
    }

    // ============================================================
    // STEP 5. Summary 병합
    // ============================================================

    final baseSummary = await summaryFuture;

    final summary = DashboardMetricSummary(
      todayReservations: todayHub.reservations.length,
      examinationProgress: baseSummary.examinationProgress,
      aiPending: baseSummary.aiPending,
      consultationPending: baseSummary.consultationPending,
      signoffPending: baseSummary.signoffPending,
      importantNotifications: baseSummary.importantNotifications,
      errorCount:
          baseSummary.errorCount +
          examinationErrorCount +
          todayHub.errorCount +
          recentPatientsErrorCount +
          todosErrorCount,
    );

    // 알림 목록 로딩 완료
    await notificationFuture;

    // Announcements : 공지사항 전용 API
    List<DashboardAnnouncement> announcements = [];
    var announcementsLoadFailed = false;

    try {
      announcements = await announcementsFuture;
    } catch (error) {
      announcementsLoadFailed = true;

      debugPrint('[DASHBOARD] 공지사항 조회 실패: $error');
    }

    return _DashboardPageData(
      summary: summary,
      overview: overview,
      todayHub: todayHub,
      examinationOrders: examinationOrders,
      recentPatients: recentPatients,
      recentPatientTotal: recentPatientTotal,
      recentPatientsLoadFailed: recentPatientsLoadFailed,
      todos: todos,
      todosLoadFailed: todosLoadFailed,
      announcements: announcements,
      announcementsLoadFailed: announcementsLoadFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return AppShell(
      pageTitle: '대시보드',
      selectedIndex: 0,
      body: Container(
        color: context.appBackground,
        child: FutureBuilder<_DashboardPageData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? _DashboardPageData.empty;

            final summary = data.summary;
            final overview = data.overview;
            final todayHub = data.todayHub;

            final examinationOrders = data.examinationOrders;

            final announcements = data.announcements;
            final announcementsLoadFailed = data.announcementsLoadFailed;

            final recentPatients = data.recentPatients;
            final recentPatientTotal = data.recentPatientTotal;
            final recentPatientsLoadFailed = data.recentPatientsLoadFailed;

            final todos = data.todos;
            final todosLoadFailed = data.todosLoadFailed;

            final metricSummary = DashboardMetricSummary(
              todayReservations: summary.todayReservations,
              examinationProgress: summary.examinationProgress,
              aiPending: summary.aiPending,
              consultationPending: summary.consultationPending,
              signoffPending: summary.signoffPending,
              importantNotifications: notificationProvider.unreadCount,
              errorCount: summary.errorCount,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScaler = MediaQuery.textScalerOf(context);

                  final textScale = textScaler.scale(16) / 16;

                  final isLargeText = textScale >= 1.25;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================================
                      // 1. Top KPI
                      // ==========================================================
                      DashboardMetricGrid(
                        summary: metricSummary,
                        onReservationsTap: () {
                          context.go('/appointments');
                        },
                        onExaminationsTap: () {
                          context.go('/examinations');
                        },
                        onAiTap: () {
                          context.go('/ai');
                        },
                        onConsultationsTap: () {
                          context.go('/consult');
                        },
                      ),

                      const SizedBox(height: 10),

                      // ==========================================================
                      // 2. Today / Recent / Todo
                      // ==========================================================
                      _DashboardMainRow(
                        width: constraints.maxWidth,
                        isLargeText: isLargeText,
                        todayHub: todayHub,
                        recentPatients: recentPatients,
                        recentPatientTotal: recentPatientTotal,
                        recentPatientsLoadFailed: recentPatientsLoadFailed,
                        todos: todos,
                        todosLoadFailed: todosLoadFailed,
                      ),

                      const SizedBox(height: 10),

                      // ==========================================================
                      // 3. Notice / Consultation
                      // ==========================================================
                      _DashboardSupportRow(
                        width: constraints.maxWidth,
                        isLargeText: isLargeText,
                        consultations: overview.consultations,
                        announcements: announcements,
                        announcementsLoadFailed: announcementsLoadFailed,
                      ),

                      const SizedBox(height: 10),

                      // ==========================================================
                      // 4. Work Status
                      // ==========================================================
                      DashboardWorkStatusPanel(
                        examinationOrders: examinationOrders,
                        aiStatus: overview.aiStatus,
                        workItems: overview.workItems,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardPageData {
  final DashboardMetricSummary summary;
  final DashboardOverviewData overview;
  final TodayHubData todayHub;

  final List<ExaminationOrderUiModel> examinationOrders;
  final List<PatientUiModel> recentPatients;
  final List<DashboardAnnouncement> announcements;
  final bool announcementsLoadFailed;
  final int recentPatientTotal;
  final bool recentPatientsLoadFailed;

  final List<StaffTodo> todos;
  final bool todosLoadFailed;

  const _DashboardPageData({
    required this.summary,
    required this.overview,
    required this.todayHub,
    required this.examinationOrders,
    required this.recentPatients,
    required this.recentPatientTotal,
    required this.recentPatientsLoadFailed,
    required this.todos,
    required this.todosLoadFailed,
    required this.announcements,
    required this.announcementsLoadFailed,
  });

  static final empty = _DashboardPageData(
    summary: DashboardMetricSummary.empty,
    overview: DashboardOverviewData.empty(),
    todayHub: TodayHubData.empty,
    examinationOrders: const [],
    recentPatients: const [],
    recentPatientTotal: 0,
    recentPatientsLoadFailed: false,
    todos: const [],
    todosLoadFailed: false,
    announcements: const [],
    announcementsLoadFailed: false,
  );
}

// ============================================================
// Dashboard Main Row
// 오늘 일정 / 최근 본 환자 / 오늘 To-do
// ============================================================

class _DashboardMainRow extends StatelessWidget {
  final double width;
  final bool isLargeText;

  final TodayHubData todayHub;

  final List<PatientUiModel> recentPatients;

  final int recentPatientTotal;

  final bool recentPatientsLoadFailed;

  final List<StaffTodo> todos;
  final bool todosLoadFailed;

  const _DashboardMainRow({
    required this.width,
    required this.isLargeText,
    required this.todayHub,
    required this.recentPatients,
    required this.recentPatientTotal,
    required this.recentPatientsLoadFailed,
    required this.todos,
    required this.todosLoadFailed,
  });

  @override
  Widget build(BuildContext context) {
    final todayCard = TodayHubCard(data: todayHub);

    final recentCard = RecentPatientsCard(
      patients: recentPatients,
      totalCount: recentPatientTotal,
      loadFailed: recentPatientsLoadFailed,
    );

    final todoCard = MyTodoSection(items: todos, loadFailed: todosLoadFailed);

    if (width >= 900 && !isLargeText) {
      const rowHeight = 265.0;

      return SizedBox(
        height: rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 7, child: todayCard),

            const SizedBox(width: 10),

            Expanded(flex: 2, child: recentCard),

            const SizedBox(width: 10),

            Expanded(flex: 3, child: todoCard),
          ],
        ),
      );
    }

    return Column(
      children: [
        todayCard,

        const SizedBox(height: 10),

        recentCard,

        const SizedBox(height: 10),

        todoCard,
      ],
    );
  }
}

// ============================================================
// Dashboard Support Row
// 공지사항 / 받은 협진
// ============================================================

class _DashboardSupportRow extends StatelessWidget {
  final double width;
  final bool isLargeText;

  final List<DashboardConsultationData> consultations;
  final List<DashboardAnnouncement> announcements;
  final bool announcementsLoadFailed;

  const _DashboardSupportRow({
    required this.width,
    required this.isLargeText,
    required this.consultations,
    required this.announcements,
    required this.announcementsLoadFailed,
  });

  @override
  Widget build(BuildContext context) {
    final noticeCard = DashboardAnnouncementCard(
      announcements: announcements,
      loadFailed: announcementsLoadFailed,
    );

    final consultationCard = ReceivedConsultationsCard(data: consultations);

    if (width >= 900 && !isLargeText) {
      const rowHeight = 170.0;

      return SizedBox(
        height: rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 8, child: noticeCard),

            const SizedBox(width: 10),

            Expanded(flex: 6, child: consultationCard),
          ],
        ),
      );
    }

    return Column(
      children: [noticeCard, const SizedBox(height: 10), consultationCard],
    );
  }
}
