import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_overview_data.dart';
import 'dashboard_section_card.dart';

// ============================================================
// STEP 1. Review Queue Card
// DashboardOverviewData.workItems를 받아서 표시
// 자체 API 호출 없음
// ============================================================

class ReviewQueueCard extends StatelessWidget {
  final List<DashboardWorkItemData> data;

  const ReviewQueueCard({super.key, required this.data});

  // ============================================================
  // STEP 2. 검토 대기 건수 계산
  // ============================================================

  bool _isPending(DashboardWorkItemData item) {
    final status = item.status.trim().toUpperCase();

    return status != 'DONE' && status != 'COMPLETED';
  }

  int get _aiCount {
    return data.where((item) {
      if (!_isPending(item)) {
        return false;
      }

      final workType = item.workType.trim().toUpperCase();

      return workType.contains('AI');
    }).length;
  }

  int get _cdssCount {
    return data.where((item) {
      if (!_isPending(item)) {
        return false;
      }

      final workType = item.workType.trim().toUpperCase();

      return workType.contains('CDSS');
    }).length;
  }

  int get _reportCount {
    return data.where((item) {
      if (!_isPending(item)) {
        return false;
      }

      final workType = item.workType.trim().toUpperCase();

      return workType.contains('REPORT') || workType.contains('SIGN');
    }).length;
  }

  int get _totalCount {
    return _aiCount + _cdssCount + _reportCount;
  }

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '검토 대기',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '처리할 검토 업무',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$_totalCount건',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _ReviewRow(
          icon: Icons.auto_awesome_outlined,
          label: 'AI 결과 검토',
          count: _aiCount,
          color: AppColors.primaryBlue,
          onTap: () {
            context.go('/ai');
          },
        ),

        const SizedBox(height: 7),

        _ReviewRow(
          icon: Icons.shield_outlined,
          label: 'CDSS 검토',
          count: _cdssCount,
          color: AppColors.success,
          onTap: () {
            context.go('/ai');
          },
        ),

        const SizedBox(height: 7),

        _ReviewRow(
          icon: Icons.fact_check_outlined,
          label: '보고서·서명 검토',
          count: _reportCount,
          color: AppColors.warning,
          onTap: null,
        ),

        if (_totalCount == 0) ...[
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '현재 검토 대기 항목이 없습니다.',
              style: TextStyle(fontSize: 8.8, color: context.appTextSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// STEP 4. Review Row
// ============================================================

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: context.appBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: count > 0 ? color : context.appTextSecondary,
                ),
              ),

              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: context.appTextSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
