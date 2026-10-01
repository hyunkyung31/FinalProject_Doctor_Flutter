import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import '../../data/models/dashboard_overview_data.dart';

// ============================================================
// Dashboard Work Status Panel
// 검사 / AI / 검토 현황을 하나의 Panel로 표시
// ============================================================

class DashboardWorkStatusPanel extends StatelessWidget {
  final List<ExaminationOrderUiModel> examinationOrders;
  final DashboardAiStatusData aiStatus;
  final List<DashboardWorkItemData> workItems;

  const DashboardWorkStatusPanel({
    super.key,
    required this.examinationOrders,
    required this.aiStatus,
    required this.workItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 14,
                  color: context.appBrand,
                ),

                const SizedBox(width: 7),

                Text(
                  '업무 현황',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.appBorder),

          // ======================================================
          // Body
          // ======================================================
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ExaminationWorkStatus(
                          orders: examinationOrders,
                        ),
                      ),

                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: context.appBorder,
                      ),

                      Expanded(child: _AiWorkStatus(data: aiStatus)),

                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: context.appBorder,
                      ),

                      Expanded(child: _ReviewWorkStatus(items: workItems)),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  _ExaminationWorkStatus(orders: examinationOrders),

                  Divider(height: 1, color: context.appBorder),

                  _AiWorkStatus(data: aiStatus),

                  Divider(height: 1, color: context.appBorder),

                  _ReviewWorkStatus(items: workItems),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Examination Status
// ============================================================

class _ExaminationWorkStatus extends StatelessWidget {
  final List<ExaminationOrderUiModel> orders;

  const _ExaminationWorkStatus({required this.orders});

  int _count(String target) {
    return orders.where((item) {
      return item.status.toUpperCase() == target;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _count('ORDERED');
    final scheduled = _count('SCHEDULED');
    final completed = _count('COMPLETED');

    return _WorkSection(
      title: '검사 주문',
      child: Wrap(
        spacing: 26,
        runSpacing: 8,
        children: [
          _WorkNumber(label: '주문 대기', value: ordered, color: AppColors.warning),
          _WorkNumber(
            label: '예약',
            value: scheduled,
            color: AppColors.primaryBlue,
          ),
          _WorkNumber(
            label: '누적 완료',
            value: completed,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI Status
// ============================================================

class _AiWorkStatus extends StatelessWidget {
  final DashboardAiStatusData data;

  const _AiWorkStatus({required this.data});

  @override
  Widget build(BuildContext context) {
    return _WorkSection(
      title: 'AI 분석',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WorkNumber(
                  label: '대기',
                  value: data.queued,
                  color: AppColors.warning,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: _WorkNumber(
                  label: '진행',
                  value: data.running,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WorkNumber(
                  label: '완료',
                  value: data.completed,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: _WorkNumber(
                  label: '실패',
                  value: data.failed,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Review Status
// ============================================================

class _ReviewWorkStatus extends StatelessWidget {
  final List<DashboardWorkItemData> items;

  const _ReviewWorkStatus({required this.items});

  int get _pendingCount {
    return items.where((item) {
      final status = item.status.trim().toUpperCase();
      final workType = item.workType.trim().toUpperCase();

      final isPending = status == 'TODO' || status == 'IN_PROGRESS';

      final isReviewWork =
          workType.contains('AI') ||
          workType.contains('CDSS') ||
          workType.contains('REPORT') ||
          workType.contains('SIGN');

      return isPending && isReviewWork;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingCount;

    return _WorkSection(
      title: '검토 대기',
      child: pendingCount == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 검토 대기 없음',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.appTextSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      if (i < 2) const SizedBox(width: 4),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  '$pendingCount',
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),

                const SizedBox(width: 6),

                Text(
                  '건 검토 대기',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// Common Work Section
// ============================================================

class _WorkSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _WorkSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 9),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// Common Work Number
// ============================================================

class _WorkNumber extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _WorkNumber({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: context.appTextSecondary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '$value',
            style: TextStyle(
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
