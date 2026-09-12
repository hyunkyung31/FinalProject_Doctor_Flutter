import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/staff_schedule.dart';

// ============================================================
// STEP 1. Staff Schedule Service
// ============================================================

class ScheduleService {
  final ApiClient apiClient;

  ScheduleService({required this.apiClient});

  // ============================================================
  // STEP 2. In-Memory Cache
  // ============================================================

  static List<StaffSchedule>? _cachedSchedules;
  static DateTime? _lastFetchedAt;

  static const Duration _cacheDuration = Duration(minutes: 1);

  // ============================================================
  // STEP 3. 의료진 일정 조회
  //
  // forceRefresh == false
  // → 캐시가 유효하면 API 호출 없이 즉시 반환
  //
  // forceRefresh == true
  // → 무조건 서버에서 다시 조회
  // ============================================================

  Future<List<StaffSchedule>> fetchSchedules({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    final hasValidCache =
        _cachedSchedules != null &&
        _lastFetchedAt != null &&
        now.difference(_lastFetchedAt!) < _cacheDuration;

    if (!forceRefresh && hasValidCache) {
      return _cachedSchedules!;
    }

    final response = await apiClient.dio.get(ApiEndpoints.staffSchedules);

    final data = response.data;

    List<StaffSchedule> schedules;

    // ==========================================================
    // 일반 List 응답
    // ==========================================================

    if (data is List) {
      schedules = data
          .whereType<Map>()
          .map(
            (item) => StaffSchedule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    // ==========================================================
    // Pagination 응답
    // ==========================================================
    else if (data is Map && data['results'] is List) {
      final results = data['results'] as List;

      schedules = results
          .whereType<Map>()
          .map(
            (item) => StaffSchedule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } else {
      throw const FormatException('의료진 일정 응답 형식이 올바르지 않습니다.');
    }

    // ==========================================================
    // Cache Update
    // ==========================================================

    _cachedSchedules = schedules;
    _lastFetchedAt = now;

    return schedules;
  }

  // ============================================================
  // STEP 4. Cache 초기화
  // ============================================================

  static void clearCache() {
    _cachedSchedules = null;
    _lastFetchedAt = null;
  }

  // ============================================================
  // 일정 등록
  // POST /staff/schedules/
  // ============================================================

  Future<StaffSchedule> createSchedule({
    required String title,
    required String scheduleType,
    required DateTime startsAt,
    required DateTime endsAt,
    required String description,
    required bool isAllDay,
    required String color,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.staffSchedules,
      data: {
        'title': title,
        'schedule_type': scheduleType,
        'starts_at': _toServerDateTime(startsAt),
        'ends_at': _toServerDateTime(endsAt),
        'description': description,
        'is_all_day': isAllDay,
        'color': color,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('일정 등록 응답 형식이 올바르지 않습니다.');
    }

    final schedule = StaffSchedule.fromJson(Map<String, dynamic>.from(data));

    // 등록 후 기존 캐시 제거
    clearCache();

    return schedule;
  }

  // ============================================================
  // 일정 수정
  // PATCH /staff/schedules/{id}/
  // ============================================================

  Future<StaffSchedule> updateSchedule({
    required int scheduleId,
    required String title,
    required String scheduleType,
    required DateTime startsAt,
    required DateTime endsAt,
    required String description,
    required bool isAllDay,
    required String color,
  }) async {
    final response = await apiClient.dio.patch(
      '${ApiEndpoints.staffSchedules}$scheduleId/',
      data: {
        'title': title,
        'schedule_type': scheduleType,
        'starts_at': _toServerDateTime(startsAt),
        'ends_at': _toServerDateTime(endsAt),
        'description': description,
        'is_all_day': isAllDay,
        'color': color,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('일정 수정 응답 형식이 올바르지 않습니다.');
    }

    final schedule = StaffSchedule.fromJson(Map<String, dynamic>.from(data));

    // ==========================================================
    // 수정 후 기존 Cache 제거
    // ==========================================================

    clearCache();

    return schedule;
  }

  // ============================================================
  // 일정 삭제
  // DELETE /staff/schedules/{id}/
  // ============================================================

  Future<void> deleteSchedule({required int scheduleId}) async {
    await apiClient.dio.delete('${ApiEndpoints.staffSchedules}$scheduleId/');

    // ==========================================================
    // 삭제 후 기존 Cache 제거
    // ==========================================================

    clearCache();
  }

  // ============================================================
  // 서버 전송용 DateTime
  // Korea +09:00 형태로 변환
  // ============================================================

  String _toServerDateTime(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:$second+09:00';
  }
}
