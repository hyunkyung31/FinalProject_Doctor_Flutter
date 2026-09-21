import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

import '../models/attendance_request.dart';

// ============================================================
// STEP 1. Attendance Request Service
// ============================================================

class AttendanceRequestService {
  final ApiClient apiClient;

  const AttendanceRequestService({required this.apiClient});

  // ============================================================
  // STEP 2. 내 휴무 신청 목록
  //
  // GET /staff/attendance-requests/
  // ============================================================

  Future<List<AttendanceRequest>> fetchMyRequests({
    String? status,
    String? type,
    int? year,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.staffAttendanceRequests,
      queryParameters: {'status': ?status, 'type': ?type, 'year': ?year},
    );

    final data = response.data;

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => AttendanceRequest.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // STEP 3. 휴무 신청 생성
  //
  // POST /staff/attendance-requests/
  // ============================================================

  Future<AttendanceRequest> createRequest({
    required AttendanceType attendanceType,
    required DateTime startDate,
    required DateTime endDate,
    required bool isAllDay,
    String? startTime,
    String? endTime,
    String? memo,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.staffAttendanceRequests,
      data: {
        'attendance_type': attendanceType.apiValue,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'start_time': startTime,
        'end_time': endTime,
        'is_all_day': isAllDay,
        'memo': _nullableText(memo),
      },
    );

    return AttendanceRequest.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // ============================================================
  // STEP 4. 내 휴무 신청 취소
  //
  // POST /staff/attendance-requests/{request_id}/cancel/
  // ============================================================

  Future<void> cancelRequest(int requestId) async {
    await apiClient.dio.post(
      ApiEndpoints.staffAttendanceRequestCancel(requestId),
    );
  }

  // ============================================================
  // STEP 5. 승인권자용 휴무 요청 목록
  //
  // GET /staff/admin/attendance-requests/
  // ============================================================

  Future<List<AttendanceRequest>> fetchAdminRequests({
    int? departmentId,
    String? status,
    String? type,
    int? userId,
    int? year,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.staffAdminAttendanceRequests,
      queryParameters: {
        'department_id': ?departmentId,
        'status': ?status,
        'type': ?type,
        'user_id': ?userId,
        'year': ?year,
      },
    );

    final data = response.data;

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => AttendanceRequest.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // STEP 6. 휴무 승인
  //
  // POST
  // /staff/admin/attendance-requests/{request_id}/approve/
  // ============================================================

  Future<void> approveRequest({
    required int requestId,
    required String reviewComment,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.staffAdminAttendanceRequestApprove(requestId),
      data: {'review_comment': reviewComment.trim()},
    );
  }

  // ============================================================
  // STEP 7. 휴무 반려
  //
  // POST
  // /staff/admin/attendance-requests/{request_id}/reject/
  // ============================================================

  Future<void> rejectRequest({
    required int requestId,
    required String reviewComment,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.staffAdminAttendanceRequestReject(requestId),
      data: {'review_comment': reviewComment.trim()},
    );
  }

  // ============================================================
  // STEP 8. Helper
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // STEP 8. 내 연차 현황 조회
  //
  // GET /staff/leave-balance/
  // ============================================================

  Future<LeaveBalance> fetchLeaveBalance() async {
    final response = await apiClient.dio.get(ApiEndpoints.staffLeaveBalance);

    return LeaveBalance.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
