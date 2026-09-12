import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

// ============================================================
// STEP 1. Work Item Service
// ============================================================

class WorkItemService {
  final ApiClient apiClient;

  WorkItemService({required this.apiClient});

  // ==========================================================
  // 로그인 사용자의 업무 목록 조회
  //
  // GET /api/staff/work-items/
  // ==========================================================

  Future<List<Map<String, dynamic>>> fetchWorkItems() async {
    final response = await apiClient.dio.get(ApiEndpoints.workItems);

    debugPrint(
      '[WORK ITEMS] status=${response.statusCode}, data=${response.data}',
    );

    final data = response.data;

    // ========================================================
    // 일반 List 응답
    // []
    // [{...}, {...}]
    // ========================================================

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // ========================================================
    // Pagination 형태도 대응
    // {"results": [...]}
    // ========================================================

    if (data is Map && data['results'] is List) {
      final results = data['results'] as List;

      return results
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw const FormatException('Work Item 응답 형식이 올바르지 않습니다.');
  }
}
