import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../data/services/dashboard_metric_service.dart';

// ============================================================
// Dashboard Metric Grid
// 상단 Compact KPI Strip
// ============================================================

class DashboardMetricGrid extends StatelessWidget {
  final DashboardMetricSummary summary;

  final VoidCallback? onReservationsTap;
  final VoidCallback? onExaminationsTap;
  final VoidCallback? onAiTap;
  final VoidCallback? onConsultationsTap;

  const DashboardMetricGrid({
    super.key,
    required this.summary,
    this.onReservationsTap,
    this.onExaminationsTap,
    this.onAiTap,
    this.onConsultationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        title: '오늘 예약',
        value: summary.todayReservations,
        icon: Icons.calendar_today_outlined,
        onTap: onReservationsTap,
        emphasized: true,
      ),
      _MetricData(
        title: '검사 진행',
        value: summary.examinationProgress,
        icon: Icons.science_outlined,
        onTap: onExaminationsTap,
      ),
      _MetricData(
        title: 'AI 대기·진행',
        value: summary.aiPending,
        icon: Icons.auto_awesome_outlined,
        onTap: onAiTap,
      ),
      _MetricData(
        title: '처리 대기 협진',
        value: summary.consultationPending,
        icon: Icons.medical_services_outlined,
        onTap: onConsultationsTap,
      ),
      _MetricData(
        title: '승인 대기',
        value: summary.signoffPending,
        icon: Icons.assignment_turned_in_outlined,
      ),
      _MetricData(
        title: '주요 알림',
        value: summary.importantNotifications,
        icon: Icons.notifications_none_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 980
            ? 6
            : constraints.maxWidth >= 620
            ? 3
            : 2;

        const gap = 8.0;

        final cardWidth =
            (constraints.maxWidth - gap * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _MetricCard(data: item),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================
// Metric Data
// ============================================================

class _MetricData {
  final String title;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.emphasized = false,
  });
}

// ============================================================
// Metric Card
// ============================================================

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final borderColor = data.emphasized ? context.appBrand : context.appBorder;

    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(data.icon, size: 15, color: context.appBrand),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Text(
                '${data.value}',
                style: TextStyle(
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
