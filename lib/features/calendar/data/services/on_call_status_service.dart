import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/on_call_schedule.dart';

// ============================================================
// STEP 1. On-Call Status Service
//
// 1) GET /staff/admin/schedules/
// 2) GET /doctors/
// 3) user 기준으로 일정 + 의료진 정보 결합
// 4) ON_CALL + ACTIVE만 반환
// ============================================================

class OnCallStatusService {
  final ApiClient apiClient;

  const OnCallStatusService({required this.apiClient});

  // ============================================================
  // STEP 2. 실제 당직 현황 조회
  // ============================================================

  Future<List<OnCallSchedule>> fetchOnCallSchedules({
    required int? currentUserId,
  }) async {
    final responses = await Future.wait([
      apiClient.dio.get(ApiEndpoints.staffAdminSchedules),
      apiClient.dio.get(ApiEndpoints.doctors),
    ]);

    final scheduleRows = _extractList(responses[0].data);

    final doctorRows = _extractList(responses[1].data);

    final doctorsByUser = <int, Map<String, dynamic>>{};

    for (final row in doctorRows) {
      final userId = _toNullableInt(row['user']);

      if (userId == null) {
        continue;
      }

      doctorsByUser[userId] = row;
    }

    final result = <OnCallSchedule>[];

    for (final row in scheduleRows) {
      final scheduleType =
          row['schedule_type']?.toString().trim().toUpperCase() ?? '';

      final status = row['status']?.toString().trim().toUpperCase() ?? '';

      if (scheduleType != 'ON_CALL' || status != 'ACTIVE') {
        continue;
      }

      final id = _toNullableInt(row['id']);

      final userId = _toNullableInt(row['user']);

      final startsAt = _toDateTime(row['starts_at']);

      final endsAt = _toDateTime(row['ends_at']);

      if (id == null || userId == null || startsAt == null || endsAt == null) {
        continue;
      }

      final doctor = doctorsByUser[userId];

      final title = row['title']?.toString().trim() ?? '';

      final doctorName = doctor?['name']?.toString().trim();

      final departmentName = doctor?['department_name']?.toString().trim();

      result.add(
        OnCallSchedule(
          id: id,
          userId: userId,
          title: title,
          startsAt: startsAt,
          endsAt: endsAt,
          doctorName: doctorName != null && doctorName.isNotEmpty
              ? doctorName
              : _fallbackDoctorName(title, userId),
          departmentId: _toNullableInt(doctor?['department']),
          department: departmentName != null && departmentName.isNotEmpty
              ? departmentName
              : '진료과 정보 없음',
          dutyType: _resolveDutyType(startsAt, endsAt),
          status: status,
          isMine: currentUserId != null && currentUserId == userId,
        ),
      );
    }

    result.sort((a, b) {
      final dateCompare = a.startsAt.compareTo(b.startsAt);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.doctorName.compareTo(b.doctorName);
    });

    return result;
  }

  // ============================================================
  // STEP 3. List Response Parsing
  //
  // admin schedules: List
  // doctors: { count, next, previous, results }
  // 둘 다 대응
  // ============================================================

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map && data['results'] is List) {
      final results = data['results'] as List;

      return results
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw const FormatException('당직 현황 API 응답 형식이 올바르지 않습니다.');
  }

  // ============================================================
  // STEP 4. Duty Label
  //
  // Backend는 schedule_type=ON_CALL만 제공하므로,
  // 날짜를 넘기는 당직은 UI에서 "야간 당직"으로 표시.
  // ============================================================

  String _resolveDutyType(DateTime startsAt, DateTime endsAt) {
    final start = startsAt.toLocal();
    final end = endsAt.toLocal();

    final crossesDay =
        start.year != end.year ||
        start.month != end.month ||
        start.day != end.day;

    if (crossesDay || start.hour >= 17) {
      return '야간 당직';
    }

    return '당직';
  }

  // ============================================================
  // STEP 5. Fallback
  // ============================================================

  String _fallbackDoctorName(String title, int userId) {
    final cleaned = title.replaceFirst(RegExp(r'\s*당직근무\s*$'), '').trim();

    if (cleaned.isNotEmpty) {
      return cleaned;
    }

    return '의료진 #$userId';
  }

  // ============================================================
  // STEP 6. Parsing Helpers
  // ============================================================

  int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
