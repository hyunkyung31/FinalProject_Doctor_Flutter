import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_overview_data.dart';
import 'dashboard_section_card.dart';

// ============================================================
// STEP 1. Received Consultations Card
// DashboardOverviewData.consultations 사용
// 자체 API 호출 없음
// ============================================================

class ReceivedConsultationsCard extends StatelessWidget {
  final List<DashboardConsultationData> data;

  const ReceivedConsultationsCard({super.key, required this.data});

  // ============================================================
  // STEP 2. 상태별 건수
  // ============================================================

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

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: '받은 협진',
      actionLabel: '전체보기',
      onAction: () {
        context.go('/consult');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 170,
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
        Row(
          children: [
            _CountBadge(
              label: '요청',
              count: _requestedCount,
              color: AppColors.warning,
              background: AppColors.warningBackground,
            ),

            const SizedBox(width: 6),

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
                fontSize: 8.8,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        for (final item in data.take(4)) _ConsultationRow(item: item),
      ],
    );
  }
}

// ============================================================
// STEP 4. Count Badge
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

// ============================================================
// STEP 5. Consultation Row
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

    return InkWell(
      onTap: () {
        context.go('/consult');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isUrgent
                    ? AppColors.dangerBackground
                    : context.appBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 15,
                color: _isUrgent ? AppColors.danger : context.appBrand,
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

            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBackground(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
            ),

            const SizedBox(width: 3),

            Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: context.appTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Subtitle
// overview API에 requesterName / department가 없으므로
// 환자 정보 + 기한으로 구성
// ============================================================

String _subtitle(DashboardConsultationData item) {
  final patientName = item.patientName.trim().isEmpty
      ? '환자명 미확인'
      : item.patientName.trim();

  final dueText = item.dueAt == null
      ? ''
      : ' · 기한 ${_formatDateTime(item.dueAt!)}';

  return '$patientName · 환자 #${item.patientId}$dueText';
}

// ============================================================
// STEP 7. Status
// ============================================================

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

// ============================================================
// STEP 8. Date Format
// ============================================================

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$month.$day $hour:$minute';
}
