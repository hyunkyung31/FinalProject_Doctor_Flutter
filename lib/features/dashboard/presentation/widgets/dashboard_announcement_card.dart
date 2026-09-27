import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_announcement.dart';
import 'dashboard_section_card.dart';

// ============================================================
// Dashboard Announcement Card
// GET /announcements/ 결과 표시
// 자체 API 호출 없음
// ============================================================

class DashboardAnnouncementCard extends StatelessWidget {
  final List<DashboardAnnouncement> announcements;
  final bool loadFailed;

  const DashboardAnnouncementCard({
    super.key,
    required this.announcements,
    required this.loadFailed,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(title: '공지사항', child: _buildContent(context));
  }

  // ============================================================
  // Content
  // ============================================================

  Widget _buildContent(BuildContext context) {
    if (loadFailed) {
      return SizedBox(
        height: 122,
        child: Center(
          child: Text(
            '공지사항을 불러오지 못했습니다.',
            style: TextStyle(fontSize: 9, color: context.appTextSecondary),
          ),
        ),
      );
    }

    if (announcements.isEmpty) {
      return SizedBox(
        height: 122,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 20,
                color: context.appTextSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(fontSize: 9, color: context.appTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = announcements.take(4).toList();

    return Column(
      children: [
        for (int index = 0; index < visibleItems.length; index++) ...[
          _AnnouncementRow(announcement: visibleItems[index]),

          if (index < visibleItems.length - 1)
            Divider(height: 1, thickness: 1, color: context.appBorder),
        ],
      ],
    );
  }
}

// ============================================================
// Announcement Row
// ============================================================

class _AnnouncementRow extends StatelessWidget {
  final DashboardAnnouncement announcement;

  const _AnnouncementRow({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final important = announcement.isImportant;

    final markerColor = important ? AppColors.danger : context.appBrand;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (important) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '중요',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    Expanded(
                      child: Text(
                        announcement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      _formatDate(announcement.publishedAt),
                      style: TextStyle(
                        fontSize: 8,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),

                if (announcement.body.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    announcement.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.2,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Date Formatter
// Backend ISO datetime → KST MM.dd
// ============================================================

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }

  final koreaTime = dateTime.toUtc().add(const Duration(hours: 9));

  final month = koreaTime.month.toString().padLeft(2, '0');

  final day = koreaTime.day.toString().padLeft(2, '0');

  return '$month.$day';
}
