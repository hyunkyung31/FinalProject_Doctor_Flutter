import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_overview_data.dart';
import 'dashboard_section_card.dart';

// ============================================================
// Received Consultations Card
// 운영/EMR 스타일의 리스트 패널
// ============================================================

class ReceivedConsultationsCard extends StatelessWidget {
  final List<DashboardConsultationData> data;

  const ReceivedConsultationsCard({super.key, required this.data});

  int get _requestedCount {
    return data.where((item) {
      final status = item.status.trim().toUpperCase();

      return status == 'REQUESTED' || status == 'PENDING';
    }).length;
  }

  int get _inProgressCount {
    return data.where((item) {
      final status = item.status.trim().toUpperCase();

      return status == 'ACCEPTED' || status == 'IN_PROGRESS';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '받은 협진',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/consult');
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 184,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 24,
                color: context.appTextSecondary,
              ),
              const SizedBox(height: 7),
              Text(
                '현재 받은 협진이 없습니다.',
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ========================================================
        // Summary Row
        // ========================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              _CountBadge(
                label: '요청',
                count: _requestedCount,
                color: AppColors.warning,
                background: AppColors.warningBackground,
              ),

              const SizedBox(width: 5),

              _CountBadge(
                label: '진행',
                count: _inProgressCount,
                color: AppColors.primaryBlue,
                background: AppColors.surfaceSoft,
              ),

              const Spacer(),

              Text(
                '총 ${data.length}건',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),

        for (final item in data.take(4)) _ConsultationRow(item: item),
      ],
    );
  }
}

// ============================================================
// Count Badge
// ============================================================

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color background;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 7.8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Consultation Row
// ============================================================

class _ConsultationRow extends StatelessWidget {
  final DashboardConsultationData item;

  const _ConsultationRow({required this.item});

  bool get _isUrgent {
    final priority = item.priority.trim().toUpperCase();

    return priority == 'URGENT' || priority == 'HIGH' || priority == 'CRITICAL';
  }

  @override
  Widget build(BuildContext context) {
    final status = item.status.trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go('/consult');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isUrgent ? AppColors.danger : _statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _subtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBackground(status),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _subtitle(DashboardConsultationData item) {
  final patientName = item.patientName.trim().isEmpty
      ? '환자명 미확인'
      : item.patientName.trim();

  final dueText = item.dueAt == null
      ? ''
      : ' · ${_formatDateTime(item.dueAt!)}';

  return '$patientName · 환자 #${item.patientId}$dueText';
}

String _statusLabel(String status) {
  switch (status) {
    case 'REQUESTED':
    case 'PENDING':
      return '수락 대기';

    case 'ACCEPTED':
      return '수락';

    case 'IN_PROGRESS':
      return '협진 진행';

    case 'COMPLETED':
      return '완료';

    case 'WITHDRAWN':
      return '회수';

    case 'REJECTED':
      return '거절';

    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'REQUESTED':
    case 'PENDING':
      return AppColors.warning;

    case 'ACCEPTED':
    case 'IN_PROGRESS':
      return AppColors.primaryBlue;

    case 'COMPLETED':
      return AppColors.success;

    case 'REJECTED':
    case 'WITHDRAWN':
      return AppColors.danger;

    default:
      return AppColors.textSecondary;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'REQUESTED':
    case 'PENDING':
      return AppColors.warningBackground;

    case 'ACCEPTED':
    case 'IN_PROGRESS':
      return AppColors.surfaceSoft;

    case 'COMPLETED':
      return AppColors.successBackground;

    case 'REJECTED':
    case 'WITHDRAWN':
      return AppColors.dangerBackground;

    default:
      return AppColors.surfaceSoft;
  }
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}
