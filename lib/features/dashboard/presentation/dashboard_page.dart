import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/services/dashboard_metric_service.dart';
import '../data/services/today_hub_service.dart';
import '../data/models/dashboard_overview_data.dart';
import '../data/services/dashboard_overview_service.dart';

import 'widgets/dashboard_metric_grid.dart';
import 'widgets/my_todo_section.dart';
import 'widgets/today_hub_card.dart';
import 'widgets/examination_status_card.dart';
import 'widgets/ai_analysis_status_card.dart';
import 'widgets/review_queue_card.dart';
import 'widgets/recent_patients_card.dart';
import 'widgets/received_consultations_card.dart';
import 'widgets/dashboard_notification_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<_DashboardPageData>? _dashboardFuture;
  int _refreshVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _dashboardFuture ??= _loadDashboard();
  }

  Future<_DashboardPageData> _loadDashboard() async {
    final auth = context.read<AuthProvider>();

    final apiClient = auth.authService.apiClient;

    final overviewService = DashboardOverviewService(apiClient: apiClient);

    final metricService = DashboardMetricService(apiClient: apiClient);

    // 이 Future 하나를 상단/하단에서 공유
    final overviewFuture = overviewService.fetchOverview(
      date: dashboardNowKst(),
    );

    // overviewFuture와 동시에
    // 예약 / 검사 / 알림 요청도 시작됨
    final summaryFuture = metricService.fetchSummary(
      isNurse: auth.isNurse,
      doctorId: auth.currentUser?.doctorId,
      overviewFuture: overviewFuture,
    );

    DashboardOverviewData overview;

    try {
      overview = await overviewFuture;
    } catch (error) {
      debugPrint('[DASHBOARD] overview 조회 실패: $error');

      overview = DashboardOverviewData.empty();
    }

    final summary = await summaryFuture;

    return _DashboardPageData(summary: summary, overview: overview);
  }

  void _reload() {
    setState(() {
      _dashboardFuture = _loadDashboard();
      _refreshVersion += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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

            final loading = snapshot.connectionState == ConnectionState.waiting;

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
                      _DashboardHeader(
                        clinicianName: auth.currentUser?.name ?? '',
                        errorCount: summary.errorCount,
                        loading: loading,
                        onRefresh: _reload,
                      ),

                      const SizedBox(height: 14),

                      DashboardMetricGrid(
                        summary: summary,
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

                      const SizedBox(height: 14),

                      _PrimaryDashboardGrid(
                        width: constraints.maxWidth,
                        isLargeText: isLargeText,
                        refreshVersion: _refreshVersion,
                      ),

                      const SizedBox(height: 14),

                      _DashboardBottomGrid(
                        width: constraints.maxWidth,
                        isLargeText: isLargeText,
                        refreshVersion: _refreshVersion,
                        overview: overview,
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

class _DashboardHeader extends StatelessWidget {
  final String clinicianName;
  final int errorCount;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.clinicianName,
    required this.errorCount,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = dashboardNowKst();

    final name = clinicianName.trim().isEmpty ? '의료진' : clinicianName.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLINICAL OPERATIONS',
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),

              const SizedBox(height: 4),

              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 3,
                children: [
                  Text(
                    '오늘의 업무',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                  Text(
                    '$name님, 오늘 확인할 업무를 정리했습니다.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                _formatToday(now),
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        if (errorCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 5),
                Text(
                  '일부 API $errorCount건 연결 대기',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],

        OutlinedButton.icon(
          onPressed: loading ? null : onRefresh,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(94, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: BorderSide(color: context.appBorder),
            foregroundColor: context.appTextPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: context.appBrand,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: const Text(
            '새로고침',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PrimaryDashboardGrid extends StatelessWidget {
  final double width;
  final bool isLargeText;
  final int refreshVersion;

  const _PrimaryDashboardGrid({
    required this.width,
    required this.isLargeText,
    required this.refreshVersion,
  });

  @override
  Widget build(BuildContext context) {
    if (width >= 900 && !isLargeText) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TodayHubCard(refreshVersion: refreshVersion),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: MyTodoSection(refreshVersion: refreshVersion),
          ),
        ],
      );
    }

    return Column(
      children: [
        TodayHubCard(refreshVersion: refreshVersion),
        const SizedBox(height: 14),
        MyTodoSection(refreshVersion: refreshVersion),
      ],
    );
  }
}

String _formatToday(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

  return '${date.year}년 '
      '${date.month}월 '
      '${date.day}일 '
      '${weekdays[date.weekday - 1]}';
}

class _DashboardBottomGrid extends StatelessWidget {
  final double width;
  final bool isLargeText;
  final int refreshVersion;
  final DashboardOverviewData overview;

  const _DashboardBottomGrid({
    required this.width,
    required this.isLargeText,
    required this.refreshVersion,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final examinationCard = ExaminationStatusCard(
      refreshVersion: refreshVersion,
    );

    final aiCard = AiAnalysisStatusCard(data: overview.aiStatus);

    final reviewCard = ReviewQueueCard(data: overview.workItems);

    final recentPatientsCard = RecentPatientsCard(
      refreshVersion: refreshVersion,
    );

    final receivedConsultationsCard = ReceivedConsultationsCard(
      data: overview.consultations,
    );

    final notificationCard = DashboardNotificationCard(
      refreshVersion: refreshVersion,
    );

    if (width >= 900 && !isLargeText) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: examinationCard),
              const SizedBox(width: 14),
              Expanded(child: aiCard),
              const SizedBox(width: 14),
              Expanded(child: reviewCard),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: recentPatientsCard),
              const SizedBox(width: 14),
              Expanded(child: receivedConsultationsCard),
              const SizedBox(width: 14),
              Expanded(child: notificationCard),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        examinationCard,
        const SizedBox(height: 14),
        aiCard,
        const SizedBox(height: 14),
        reviewCard,
        const SizedBox(height: 14),
        recentPatientsCard,
        const SizedBox(height: 14),
        receivedConsultationsCard,
        const SizedBox(height: 14),
        notificationCard,
      ],
    );
  }
}

class _DashboardPageData {
  final DashboardMetricSummary summary;
  final DashboardOverviewData overview;

  const _DashboardPageData({required this.summary, required this.overview});

  static final empty = _DashboardPageData(
    summary: DashboardMetricSummary.empty,
    overview: DashboardOverviewData.empty(),
  );
}
