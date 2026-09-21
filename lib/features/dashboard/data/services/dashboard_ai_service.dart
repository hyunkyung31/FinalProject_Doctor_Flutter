import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class DashboardAiAnalysis {
  final int id;
  final int examinationId;
  final int requestedBy;
  final String analysisType;
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;

  const DashboardAiAnalysis({
    required this.id,
    required this.examinationId,
    required this.requestedBy,
    required this.analysisType,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
  });

  factory DashboardAiAnalysis.fromJson(Map<String, dynamic> json) {
    return DashboardAiAnalysis(
      id: _parseInt(json['id']),
      examinationId: _parseInt(json['examination']),
      requestedBy: _parseInt(json['requested_by']),
      analysisType: json['analysis_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestedAt: _parseDateTime(json['requested_at']),
      completedAt: _parseNullableDateTime(json['completed_at']),
    );
  }

  bool get isPending {
    final value = status.toUpperCase();

    return value == 'PENDING' || value == 'QUEUED';
  }

  bool get isRunning {
    return status.toUpperCase() == 'RUNNING';
  }

  bool get isSucceeded {
    return status.toUpperCase() == 'SUCCEEDED';
  }

  bool get isFailed {
    return status.toUpperCase() == 'FAILED';
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return _toKst(parsed);
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return null;
    }

    return _toKst(parsed);
  }

  static DateTime _toKst(DateTime date) {
    final kst = date.toUtc().add(const Duration(hours: 9));

    return DateTime(
      kst.year,
      kst.month,
      kst.day,
      kst.hour,
      kst.minute,
      kst.second,
    );
  }
}

class DashboardAiService {
  final ApiClient apiClient;

  DashboardAiService({required this.apiClient});

  Future<List<DashboardAiAnalysis>> fetchAnalyses() async {
    final response = await apiClient.dio.get(ApiEndpoints.aiAnalyses);

    final data = response.data;

    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['results'] is List) {
      items = data['results'] as List;
    } else {
      throw const FormatException('AI 분석 목록 응답 형식이 올바르지 않습니다.');
    }

    final analyses = items
        .whereType<Map>()
        .map(
          (item) =>
              DashboardAiAnalysis.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    analyses.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    debugPrint(
      '[DASHBOARD] AI 분석 현황 조회 완료: '
      '${analyses.length}건',
    );

    return analyses;
  }
}
