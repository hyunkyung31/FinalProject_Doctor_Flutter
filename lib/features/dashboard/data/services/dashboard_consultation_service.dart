import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class DashboardConsultationItem {
  final int id;
  final int patientId;

  final String subject;
  final String requestNote;

  final String priority;
  final String status;

  final String requesterName;
  final String requesterDepartment;

  final String assignedDoctorName;
  final String assignedDepartment;

  final DateTime? dueAt;
  final DateTime createdAt;

  const DashboardConsultationItem({
    required this.id,
    required this.patientId,
    required this.subject,
    required this.requestNote,
    required this.priority,
    required this.status,
    required this.requesterName,
    required this.requesterDepartment,
    required this.assignedDoctorName,
    required this.assignedDepartment,
    required this.dueAt,
    required this.createdAt,
  });

  factory DashboardConsultationItem.fromJson(Map<String, dynamic> json) {
    final requesterProfile = _parseMap(json['requested_by_profile']);

    final assignedProfile = _parseMap(json['assigned_doctor_profile']);

    return DashboardConsultationItem(
      id: _parseInt(json['id']),
      patientId: _parseInt(json['patient']),
      subject: json['subject']?.toString() ?? '',
      requestNote: json['request_note']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'NORMAL',
      status: json['status']?.toString() ?? '',
      requesterName: requesterProfile['name']?.toString() ?? '',
      requesterDepartment:
          requesterProfile['department_name']?.toString() ?? '',
      assignedDoctorName: assignedProfile['name']?.toString() ?? '',
      assignedDepartment: assignedProfile['department_name']?.toString() ?? '',
      dueAt: _parseNullableDateTime(json['due_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  bool get isRequested => status.toUpperCase() == 'REQUESTED';

  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';

  bool get isActive {
    final value = status.toUpperCase();

    return value != 'COMPLETED' && value != 'WITHDRAWN' && value != 'CANCELED';
  }

  bool get isUrgent {
    final value = priority.toUpperCase();

    return value == 'HIGH' || value == 'URGENT' || value == 'CRITICAL';
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
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

class DashboardConsultationService {
  final ApiClient apiClient;

  DashboardConsultationService({required this.apiClient});

  Future<List<DashboardConsultationItem>> fetchAssignedConsultations() async {
    final response = await apiClient.dio.get(
      ApiEndpoints.consultations,
      queryParameters: {'assigned_to_me': true},
    );

    final data = response.data;

    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['results'] is List) {
      items = data['results'] as List;
    } else {
      throw const FormatException('협진 목록 응답 형식이 올바르지 않습니다.');
    }

    final consultations = items
        .whereType<Map>()
        .map(
          (item) => DashboardConsultationItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.isActive)
        .toList();

    consultations.sort((a, b) {
      if (a.isUrgent != b.isUrgent) {
        return a.isUrgent ? -1 : 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    debugPrint(
      '[DASHBOARD] 받은 협진 조회 완료: '
      '${consultations.length}건',
    );

    return consultations;
  }
}
