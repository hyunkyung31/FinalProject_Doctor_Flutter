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

  // ============================================================
  // 오늘 의료진 일정 조회
  // React와 동일하게 서버에 오늘 범위(from / to)를 전달
  // ============================================================

  Future<List<TodayHubScheduleItem>> _fetchTodaySchedules() async {
    final today = _nowKst();

    // ============================================================
    // STEP 1. 오늘 KST 범위를 UTC ISO 문자열로 변환
    //
    // 예:
    // 2026-09-28 00:00 KST
    // → 2026-09-27T15:00:00.000Z
    // ============================================================

    final startUtc = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(hours: 9));

    final endUtc = DateTime.utc(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
      999,
    ).subtract(const Duration(hours: 9));

    // ============================================================
    // STEP 2. React와 동일하게 오늘 범위로 서버 조회
    // ============================================================

    final response = await apiClient.dio.get(
      ApiEndpoints.staffSchedules,
      queryParameters: {
        'from': startUtc.toIso8601String(),
        'to': endUtc.toIso8601String(),
      },
    );

    final items = _extractItems(response.data, '의료진 일정');

    final schedules = <TodayHubScheduleItem>[];

    // ============================================================
    // STEP 3. 서버가 반환한 오늘 일정 변환
    // ============================================================

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

    // ============================================================
    // STEP 4. 종일 일정 먼저 → 이후 시간순
    // ============================================================

    schedules.sort((a, b) {
      if (a.isAllDay != b.isAllDay) {
        return a.isAllDay ? -1 : 1;
      }

      return a.startsAt.compareTo(b.startsAt);
    });

    debugPrint('[DASHBOARD] 오늘 일정 조회 완료: ${schedules.length}건');

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
