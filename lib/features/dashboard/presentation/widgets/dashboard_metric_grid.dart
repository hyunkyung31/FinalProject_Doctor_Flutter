import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/dashboard_metric_service.dart';

class DashboardMetricGrid extends StatelessWidget {
  final DashboardMetricSummary summary;

  final VoidCallback? onReservationsTap;
  final VoidCallback? onExaminationsTap;
  final VoidCallback? onAiTap;
  final VoidCallback? onConsultationsTap;
  final VoidCallback? onSignoffTap;
  final VoidCallback? onNotificationsTap;

  const DashboardMetricGrid({
    super.key,
    required this.summary,
    this.onReservationsTap,
    this.onExaminationsTap,
    this.onAiTap,
    this.onConsultationsTap,
    this.onSignoffTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        icon: Icons.calendar_month_outlined,
        title: '오늘 예약',
        value: summary.todayReservations,
        description: '당일 예약 환자',
        color: AppColors.primaryBlue,
        onTap: onReservationsTap,
      ),
      _MetricItem(
        icon: Icons.science_outlined,
        title: '검사 진행',
        value: summary.examinationProgress,
        description: '예정·진행 검사',
        color: AppColors.success,
        onTap: onExaminationsTap,
      ),
      _MetricItem(
        icon: Icons.auto_awesome_outlined,
        title: 'AI 대기·진행',
        value: summary.aiPending,
        description: '검토 전 분석',
        color: AppColors.primaryBlue,
        onTap: onAiTap,
      ),
      _MetricItem(
        icon: Icons.medical_services_outlined,
        title: '처리 대기 협진',
        value: summary.consultationPending,
        description: '수락·의견 필요',
        color: AppColors.warning,
        onTap: onConsultationsTap,
      ),
      _MetricItem(
        icon: Icons.fact_check_outlined,
        title: '승인 대기',
        value: summary.signoffPending,
        description: '검토·서명 보고서',
        color: AppColors.navy,
        onTap: onSignoffTap,
      ),
      _MetricItem(
        icon: Icons.notifications_none_rounded,
        title: '주요 알림',
        value: summary.importantNotifications,
        description: '확인이 필요한 알림',
        color: AppColors.danger,
        onTap: onNotificationsTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);

        final textScale = textScaler.scale(16) / 16;

        final int columnCount;

        if (constraints.maxWidth >= 1000 && textScale < 1.25) {
          columnCount = 6;
        } else if (constraints.maxWidth >= 680) {
          columnCount = 3;
        } else {
          columnCount = 2;
        }

        const spacing = 10.0;

        final width =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _MetricCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String title;
  final int value;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _MetricItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.color,
    required this.onTap,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
