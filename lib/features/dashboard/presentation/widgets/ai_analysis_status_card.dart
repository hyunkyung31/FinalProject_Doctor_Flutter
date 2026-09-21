import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_overview_data.dart';
import 'dashboard_section_card.dart';

class AiAnalysisStatusCard extends StatelessWidget {
  final DashboardAiStatusData data;

  const AiAnalysisStatusCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'AI 분석 현황',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/ai');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
        child: Column(
          children: [
            Row(
              children: [
                _SummaryChip(
                  label: '대기',
                  count: data.queued,
                  color: AppColors.warning,
                  background: AppColors.warningBackground,
                ),
                const SizedBox(width: 5),
                _SummaryChip(
                  label: '진행',
                  count: data.running,
                  color: AppColors.primaryBlue,
                  background: AppColors.surfaceSoft,
                ),
                const SizedBox(width: 5),
                _SummaryChip(
                  label: '완료',
                  count: data.completed,
                  color: AppColors.success,
                  background: AppColors.successBackground,
                ),
                if (data.failed > 0) ...[
                  const SizedBox(width: 5),
                  _SummaryChip(
                    label: '실패',
                    count: data.failed,
                    color: AppColors.danger,
                    background: AppColors.dangerBackground,
                  ),
                ],
                const Spacer(),
                Text(
                  '총 ${data.total}건',
                  style: TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _StatusRow(
              icon: Icons.hourglass_top_rounded,
              label: '분석 대기',
              count: data.queued,
              color: AppColors.warning,
            ),

            const SizedBox(height: 7),

            _StatusRow(
              icon: Icons.autorenew_rounded,
              label: '분석 진행',
              count: data.running,
              color: AppColors.primaryBlue,
            ),

            const SizedBox(height: 7),

            _StatusRow(
              icon: Icons.check_circle_outline_rounded,
              label: '분석 완료',
              count: data.completed,
              color: AppColors.success,
            ),

            if (data.failed > 0) ...[
              const SizedBox(height: 7),
              _StatusRow(
                icon: Icons.error_outline_rounded,
                label: '분석 실패',
                count: data.failed,
                color: AppColors.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color background;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }
}
