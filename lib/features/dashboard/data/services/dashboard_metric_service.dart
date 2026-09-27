import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/dashboard_overview_data.dart';

// ============================================================
// STEP 1. Dashboard Metric Summary
// ============================================================

class DashboardMetricSummary {
  final int todayReservations;
  final int examinationProgress;
  final int aiPending;
  final int consultationPending;
  final int signoffPending;
  final int importantNotifications;
  final int errorCount;

  const DashboardMetricSummary({
    required this.todayReservations,
    required this.examinationProgress,
    required this.aiPending,
    required this.consultationPending,
    required this.signoffPending,
    required this.importantNotifications,
    required this.errorCount,
  });

  static const empty = DashboardMetricSummary(
    todayReservations: 0,
    examinationProgress: 0,
    aiPending: 0,
    consultationPending: 0,
    signoffPending: 0,
    importantNotifications: 0,
    errorCount: 0,
  );
}

// ============================================================
// STEP 2. Dashboard Metric Service
// ============================================================

class DashboardMetricService {
  final ApiClient apiClient;

  DashboardMetricService({required this.apiClient});

  Future<DashboardMetricSummary> fetchSummary({
    required Future<DashboardOverviewData> overviewFuture,
  }) async {
    var errorCount = 0;

    // ==========================================================
    // 공통 안전 실행
    // ==========================================================

    Future<T> safe<T>(
      String name,
      Future<T> Function() action,
      T fallback,
    ) async {
      try {
        return await action();
      } catch (error) {
        errorCount += 1;

        debugPrint('[DASHBOARD] $name 조회 실패: $error');

        return fallback;
      }
    }

    // ==========================================================
    // STEP 4. DashboardPage에서 이미 시작한 overview Future 공유
    // ==========================================================

    final overview = await safe<DashboardOverviewData>(
      '대시보드 개요',
      () => overviewFuture,
      DashboardOverviewData.empty(),
    );

    // ==========================================================
    // STEP 6. Summary 구성
    // ==========================================================

    return DashboardMetricSummary(
      // DashboardPage에서 TodayHubData로 최종 교체
      todayReservations: 0,

      // /dashboard/summary/
      examinationProgress: overview.summary.examinationPendingCount,

      // /dashboard/ai-status/
      aiPending: overview.aiStatus.queued + overview.aiStatus.running,

      // /dashboard/work-items/
      consultationPending: overview.consultationReviewTodoCount,

      // /dashboard/summary/
      signoffPending: overview.summary.signoffPendingCount,

      // 실제 값은 DashboardPage에서 NotificationProvider 값으로 교체
      importantNotifications: 0,

      errorCount: errorCount,
    );
  }
}
