import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/dashboard_overview_data.dart';

class DashboardOverviewService {
  final ApiClient apiClient;

  DashboardOverviewService({required this.apiClient});

  Future<DashboardOverviewData> fetchOverview({
    required DateTime date,
    int? departmentId,
  }) async {
    final dateText = _formatDate(date);

    final results = await Future.wait([
      _safeGet(
        name: 'summary',
        path: ApiEndpoints.dashboardSummary,
        queryParameters: {'date': dateText, 'department': ?departmentId},
      ),
      _safeGet(
        name: 'ai-status',
        path: ApiEndpoints.dashboardAiStatus,
        queryParameters: {'date': dateText, 'department': ?departmentId},
      ),
      _safeGet(
        name: 'consultations',
        path: ApiEndpoints.dashboardConsultations,
      ),
      _safeGet(name: 'work-items', path: ApiEndpoints.dashboardWorkItems),
    ]);

    final summaryResult = results[0];
    final aiStatusResult = results[1];
    final consultationsResult = results[2];
    final workItemsResult = results[3];

    final errorCount = results.where((result) => !result.success).length;

    final summary = summaryResult.success
        ? DashboardSummaryData.fromJson(_asMap(summaryResult.data))
        : DashboardSummaryData.empty;

    final aiStatus = aiStatusResult.success
        ? DashboardAiStatusData.fromJson(_asMap(aiStatusResult.data))
        : DashboardAiStatusData.empty;

    final consultations = consultationsResult.success
        ? _asList(consultationsResult.data)
              .whereType<Map>()
              .map(
                (item) => DashboardConsultationData.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <DashboardConsultationData>[];

    final workItems = workItemsResult.success
        ? _asList(workItemsResult.data)
              .whereType<Map>()
              .map(
                (item) => DashboardWorkItemData.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <DashboardWorkItemData>[];

    debugPrint(
      '[DASHBOARD OVERVIEW] '
      'summary=${summaryResult.success}, '
      'ai=${aiStatusResult.success}, '
      'consultations=${consultationsResult.success}, '
      'workItems=${workItemsResult.success}, '
      'errors=$errorCount',
    );

    return DashboardOverviewData(
      summary: summary,
      aiStatus: aiStatus,
      consultations: consultations,
      workItems: workItems,
      errorCount: errorCount,
    );
  }

  Future<_DashboardRequestResult> _safeGet({
    required String name,
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await apiClient.dio.get(
        path,
        queryParameters: queryParameters,
      );

      return _DashboardRequestResult(success: true, data: response.data);
    } catch (error) {
      debugPrint('[DASHBOARD OVERVIEW] $name 조회 실패: $error');

      return const _DashboardRequestResult(success: false, data: null);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }

    return const [];
  }

  String _formatDate(DateTime date) {
    final koreaTime = date.toUtc().add(const Duration(hours: 9));

    final month = koreaTime.month.toString().padLeft(2, '0');

    final day = koreaTime.day.toString().padLeft(2, '0');

    return '${koreaTime.year}-$month-$day';
  }
}

class _DashboardRequestResult {
  final bool success;
  final dynamic data;

  const _DashboardRequestResult({required this.success, required this.data});
}
