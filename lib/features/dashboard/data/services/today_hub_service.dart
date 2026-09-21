import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../appointments/data/services/appointment_service.dart';
import '../../../appointments/presentation/appointment_ui_model.dart';

class TodayHubData {
  final List<TodayHubScheduleItem> schedules;
  final List<TodayHubReservationItem> reservations;
  final int errorCount;

  const TodayHubData({
    required this.schedules,
    required this.reservations,
    required this.errorCount,
  });

  static const empty = TodayHubData(
    schedules: [],
    reservations: [],
    errorCount: 0,
  );
}

class TodayHubScheduleItem {
  final int id;
  final String title;
  final String scheduleType;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isAllDay;

  const TodayHubScheduleItem({
    required this.id,
    required this.title,
    required this.scheduleType,
    required this.startsAt,
    required this.endsAt,
    required this.isAllDay,
  });

  String get typeLabel {
    switch (scheduleType.toUpperCase()) {
      case 'CLINICAL':
        return '진료';
      case 'PERSONAL':
        return '개인 일정';
      case 'ON_CALL':
        return '당직';
      case 'OFF':
        return '휴무';
      default:
        return scheduleType;
    }
  }
}

class TodayHubReservationItem {
  final int id;
  final int? patientId;
  final String applicantName;
  final DateTime reservedAt;
  final AppointmentStatus status;

  const TodayHubReservationItem({
    required this.id,
    required this.patientId,
    required this.applicantName,
    required this.reservedAt,
    required this.status,
  });
}

class TodayHubService {
  final ApiClient apiClient;

  TodayHubService({required this.apiClient});

  Future<TodayHubData> fetchToday({
    required bool isNurse,
    required int? doctorId,
  }) async {
    var errorCount = 0;

    final schedulesFuture = _fetchTodaySchedules().catchError((Object error) {
      errorCount += 1;

      debugPrint('[DASHBOARD] 오늘 일정 조회 실패: $error');

      return <TodayHubScheduleItem>[];
    });

    final reservationsFuture =
        _fetchTodayReservations(
          isNurse: isNurse,
          doctorId: doctorId,
        ).catchError((Object error) {
          errorCount += 1;

          debugPrint('[DASHBOARD] 오늘 예약 환자 조회 실패: $error');

          return <TodayHubReservationItem>[];
        });

    final schedules = await schedulesFuture;
    final reservations = await reservationsFuture;

    return TodayHubData(
      schedules: schedules,
      reservations: reservations,
      errorCount: errorCount,
    );
  }

  Future<List<TodayHubScheduleItem>> _fetchTodaySchedules() async {
    final response = await apiClient.dio.get(ApiEndpoints.staffSchedules);

    final items = _extractItems(response.data, '의료진 일정');

    final today = _nowKst();

    final schedules = <TodayHubScheduleItem>[];

    for (final item in items) {
      final status = item['status']?.toString().toUpperCase() ?? '';

      if (status.isNotEmpty && status != 'ACTIVE') {
        continue;
      }

      final startsAt = _parseServerDateTime(item['starts_at']);

      final endsAt = _parseServerDateTime(item['ends_at']);

      if (startsAt == null || endsAt == null) {
        continue;
      }

      final sameDay =
          startsAt.year == today.year &&
          startsAt.month == today.month &&
          startsAt.day == today.day;

      if (!sameDay) {
        continue;
      }

      schedules.add(
        TodayHubScheduleItem(
          id: _parseInt(item['id']),
          title: item['title']?.toString() ?? '일정',
          scheduleType: item['schedule_type']?.toString() ?? '',
          startsAt: startsAt,
          endsAt: endsAt,
          isAllDay: item['is_all_day'] == true,
        ),
      );
    }

    schedules.sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return schedules;
  }

  Future<List<TodayHubReservationItem>> _fetchTodayReservations({
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

    final today = _nowKst();

    final reservations = appointments
        .where((appointment) {
          final reservedAt = appointment.reservedAt;

          return reservedAt.year == today.year &&
              reservedAt.month == today.month &&
              reservedAt.day == today.day;
        })
        .map((appointment) {
          return TodayHubReservationItem(
            id: appointment.id,
            patientId: appointment.patient,
            applicantName: appointment.applicantName,
            reservedAt: appointment.reservedAt,
            status: appointment.status,
          );
        })
        .toList();

    reservations.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    return reservations;
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

  DateTime? _parseServerDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return null;
    }

    final kst = parsed.toUtc().add(const Duration(hours: 9));

    return DateTime(
      kst.year,
      kst.month,
      kst.day,
      kst.hour,
      kst.minute,
      kst.second,
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

DateTime dashboardNowKst() {
  return _nowKst();
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
