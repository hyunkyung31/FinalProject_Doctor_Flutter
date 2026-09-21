import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../appointments/data/services/appointment_service.dart';
import '../models/dashboard_overview_data.dart';

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

class DashboardMetricService {
  final ApiClient apiClient;

  DashboardMetricService({required this.apiClient});

  Future<DashboardMetricSummary> fetchSummary({
    required bool isNurse,
    required int? doctorId,
    required Future<DashboardOverviewData> overviewFuture,
  }) async {
    var errorCount = 0;

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

    // 서로 의존하지 않는 요청은 동시에 시작
    final reservationsFuture = safe<int>(
      '오늘 예약',
      () => _fetchTodayReservations(isNurse: isNurse, doctorId: doctorId),
      0,
    );

    final examinationFuture = safe<int>('검사 진행', _fetchExaminationProgress, 0);

    final notificationsFuture = safe<int>(
      '미확인 알림',
      _fetchUnreadNotifications,
      0,
    );

    // DashboardPage에서 시작한 동일 Future를 공유
    final overview = await safe<DashboardOverviewData>(
      '대시보드 개요',
      () => overviewFuture,
      DashboardOverviewData.empty(),
    );

    final todayReservations = await reservationsFuture;

    final examinationProgress = await examinationFuture;

    final importantNotifications = await notificationsFuture;

    return DashboardMetricSummary(
      todayReservations: todayReservations,
      examinationProgress: examinationProgress,

      // /dashboard/ai-status/
      aiPending: overview.aiStatus.queued + overview.aiStatus.running,

      // /dashboard/work-items/
      consultationPending: overview.consultationReviewTodoCount,

      // /dashboard/summary/
      signoffPending: overview.summary.signoffPendingCount,

      // /notifications/unread-count/
      importantNotifications: importantNotifications,

      errorCount: errorCount,
    );
  }

  Future<int> _fetchTodayReservations({
    required bool isNurse,
    required int? doctorId,
  }) async {
    if (!isNurse && doctorId == null) {
      throw StateError('로그인 의사의 doctor_id를 확인할 수 없습니다.');
    }

    final service = AppointmentService(apiClient: apiClient);

    final appointments = await service.fetchAppointments(
      doctorId: isNurse ? null : doctorId,
    );

    final now = _nowKst();

    return appointments.where((appointment) {
      final reservedAt = appointment.reservedAt.toLocal();

      return reservedAt.year == now.year &&
          reservedAt.month == now.month &&
          reservedAt.day == now.day;
    }).length;
  }

  Future<int> _fetchExaminationProgress() async {
    final response = await apiClient.dio.get(ApiEndpoints.examinationOrders);

    final items = _extractItems(response.data, '검사 오더');

    return items.where((item) {
      final status = item['status']?.toString().toUpperCase() ?? '';

      return status == 'SCHEDULED' || status == 'IN_PROGRESS';
    }).length;
  }

  Future<int> _fetchUnreadNotifications() async {
    final response = await apiClient.dio.get(
      ApiEndpoints.notificationUnreadCount,
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('미확인 알림 응답 형식이 올바르지 않습니다.');
    }

    final map = Map<String, dynamic>.from(data);

    return _toInt(map['unread_count']);
  }

  List<Map<String, dynamic>> _extractItems(dynamic data, String responseName) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final results = map['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw FormatException('$responseName 응답 형식이 올바르지 않습니다.');
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

DateTime _nowKst() {
  final kst = DateTime.now().toUtc().add(const Duration(hours: 9));

  return DateTime(
    kst.year,
    kst.month,
    kst.day,
    kst.hour,
    kst.minute,
    kst.second,
  );
}
