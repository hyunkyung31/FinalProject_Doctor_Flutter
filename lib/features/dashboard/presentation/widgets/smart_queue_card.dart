import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';

import '../../data/services/work_item_service.dart';
import 'dashboard_section_card.dart';

// ============================================================
// STEP 1. Smart Queue Card
// API 상태별 UI 처리
//
// 현재 단계:
// API 성공 + [] 응답을 임시 재현
//
// 다음 단계:
// _fetchSmartQueueItems() 내부를 실제 API 호출로 교체
// ============================================================

class SmartQueueCard extends StatefulWidget {
  const SmartQueueCard({super.key});

  @override
  State<SmartQueueCard> createState() => _SmartQueueCardState();
}

class _SmartQueueCardState extends State<SmartQueueCard> {
  late Future<List<_QueueData>> _queueFuture;

  @override
  void initState() {
    super.initState();

    _queueFuture = _fetchSmartQueueItems();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
      case 'CRITICAL':
        return AppColors.danger;

      case 'HIGH':
        return AppColors.warning;

      case 'NORMAL':
      case 'MEDIUM':
        return AppColors.primaryBlue;

      default:
        return AppColors.textSecondary;
    }
  }

  // ==========================================================
  // STEP 2. Smart Queue 데이터 조회
  // ==========================================================

  Future<List<_QueueData>> _fetchSmartQueueItems() async {
    final apiClient = context.read<ApiClient>();

    final workItemService = WorkItemService(apiClient: apiClient);

    final rawItems = await workItemService.fetchWorkItems();

    // ==========================================================
    // 현재 실제 API가 []이므로
    // 그대로 Empty State 출력
    // ==========================================================

    if (rawItems.isEmpty) {
      return const <_QueueData>[];
    }

    // ==========================================================
    // 테스트 데이터가 들어왔을 경우 임시 Mapping
    //
    // 정확한 Response JSON을 확인한 뒤
    // 정식 WorkItem Model로 교체 예정
    // ==========================================================

    return rawItems.map((item) {
      final level = (item['priority'] ?? 'NORMAL').toString().toUpperCase();

      final title =
          item['title']?.toString() ?? item['type']?.toString() ?? '업무';

      return _QueueData(
        level: level,
        title: title,
        count: '1',
        color: _priorityColor(level),
      );
    }).toList();
  }

  // ==========================================================
  // STEP 3. 새로고침
  // 오류 상태 등에서 다시 조회할 때 사용
  // ==========================================================

  void _reload() {
    setState(() {
      _queueFuture = _fetchSmartQueueItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'SMART QUEUE',
      actionLabel: '업무보기',
      onAction: () {
        _showSmartQueueMessage(context, '전체 업무 Queue');
      },

      child: FutureBuilder<List<_QueueData>>(
        future: _queueFuture,
        builder: (context, snapshot) {
          // ==================================================
          // Loading
          // ==================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SmartQueueLoading();
          }

          // ==================================================
          // Error
          // ==================================================

          if (snapshot.hasError) {
            return _SmartQueueError(onRetry: _reload);
          }

          // ==================================================
          // Data
          // ==================================================

          final items = snapshot.data ?? const <_QueueData>[];

          // ==================================================
          // Empty
          // API 성공 + []
          // ==================================================

          if (items.isEmpty) {
            return const _SmartQueueEmpty();
          }

          // ==================================================
          // Queue List
          // ==================================================

          return Column(
            children: [
              for (int index = 0; index < items.length; index++) ...[
                _QueueItem(data: items[index]),

                if (index != items.length - 1) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// STEP 4. Smart Queue Empty State
// API 요청 성공 + [] 응답
// ============================================================

class _SmartQueueEmpty extends StatelessWidget {
  const _SmartQueueEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // Empty Icon
            // ==================================================
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 20,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // Empty Title
            // ==================================================
            const Text(
              '현재 처리할 업무가 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            // ==================================================
            // Empty Description
            // ==================================================
            const Text(
              '새로운 업무가 배정되면 여기에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 5. Smart Queue Loading State
// ============================================================

class _SmartQueueLoading extends StatelessWidget {
  const _SmartQueueLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Smart Queue Error State
// ============================================================

class _SmartQueueError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SmartQueueError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 24,
              color: AppColors.danger,
            ),

            const SizedBox(height: 8),

            const Text(
              '업무 목록을 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              '잠시 후 다시 시도해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Smart Queue Data
// 추후 실제 API Model로 교체 예정
// ============================================================

class _QueueData {
  final String level;
  final String title;
  final String count;
  final Color color;

  const _QueueData({
    required this.level,
    required this.title,
    required this.count,
    required this.color,
  });
}

// ============================================================
// STEP 8. Smart Queue Item
// 기존 디자인 유지
// ============================================================

class _QueueItem extends StatelessWidget {
  final _QueueData data;

  const _QueueItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showSmartQueueMessage(context, data.title);
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        child: Row(
          children: [
            // ==================================================
            // Priority Dot
            // ==================================================
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 9),

            // ==================================================
            // Priority Level
            // ==================================================
            SizedBox(
              width: 50,
              child: Text(
                data.level,
                style: TextStyle(
                  color: data.color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // ==================================================
            // Queue Title
            // ==================================================
            Expanded(
              child: Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // Count
            // ==================================================
            Text(
              data.count,
              style: TextStyle(
                color: data.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(width: 3),

            const Text(
              '건',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 9. Smart Queue Temporary Message
// 업무 상세 Route 연결 후 제거 예정
// ============================================================

void _showSmartQueueMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
}
