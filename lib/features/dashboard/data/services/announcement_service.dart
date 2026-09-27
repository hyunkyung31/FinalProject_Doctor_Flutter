import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/dashboard_announcement.dart';

// ============================================================
// Announcement Service
// 직원 공지사항 API
// ============================================================

class AnnouncementService {
  final ApiClient apiClient;

  const AnnouncementService({required this.apiClient});

  // ============================================================
  // 공지사항 목록
  // GET /announcements/
  //
  // Backend 지원 필터:
  // category
  // priority
  // ============================================================

  Future<List<DashboardAnnouncement>> fetchAnnouncements({
    String? category,
    String? priority,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.announcements,
      queryParameters: {
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),

        if (priority != null && priority.trim().isNotEmpty)
          'priority': priority.trim(),
      },
    );

    final data = response.data;

    if (data is! List) {
      throw const FormatException('공지사항 목록 응답 형식이 올바르지 않습니다.');
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              DashboardAnnouncement.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // 공지사항 상세
  // GET /announcements/{id}/
  // ============================================================

  Future<DashboardAnnouncement> fetchAnnouncementDetail(
    int announcementId,
  ) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.announcementDetail(announcementId),
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('공지사항 상세 응답 형식이 올바르지 않습니다.');
    }

    return DashboardAnnouncement.fromJson(Map<String, dynamic>.from(data));
  }
}
