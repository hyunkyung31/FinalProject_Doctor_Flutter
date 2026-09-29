import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_announcement.dart';
import 'dashboard_section_card.dart';

// ============================================================
// Dashboard Announcement Card
// GET /announcements/ 결과 표시
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
    return DashboardSectionCard(
      title: '공지사항',
      actionLabel: announcements.isEmpty
          ? null
          : '${announcements.length}  전체보기',
      onAction: announcements.isEmpty
          ? null
          : () {
              _showAllAnnouncements(context);
            },
      child: _buildContent(context),
    );
  }

  // ============================================================
  // 전체 공지사항
  // ============================================================

  Future<void> _showAllAnnouncements(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 36,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 650),
            child: Column(
              children: [
                // ==================================================
                // Header
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 10, 5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 18,
                        color: dialogContext.appBrand,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '공지사항',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: dialogContext.appTextPrimary,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '총 ${announcements.length}건',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: dialogContext.appTextSecondary,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip: '닫기',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: dialogContext.appBorder),

                // ==================================================
                // List
                // ==================================================
                Expanded(
                  child: ListView.separated(
                    itemCount: announcements.length,
                    separatorBuilder: (_, _) {
                      return Divider(height: 1, color: dialogContext.appBorder);
                    },
                    itemBuilder: (context, index) {
                      return _AnnouncementRow(
                        announcement: announcements[index],
                        expanded: true,
                        onTap: () {
                          _showAnnouncementDetail(
                            context,
                            announcements[index],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Announcement Detail
  // 실제 API에서 받아온 공지사항 데이터 상세 표시
  // ============================================================

  Future<void> _showAnnouncementDetail(
    BuildContext context,
    DashboardAnnouncement announcement,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final important = announcement.isImportant;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 56,
            vertical: 44,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // Header
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 8, 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 18,
                        color: dialogContext.appBrand,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '공지사항',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: dialogContext.appTextPrimary,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip: '닫기',
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: dialogContext.appBorder),

                // ==================================================
                // Detail
                // ==================================================
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 7, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (important) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBackground,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '중요',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),
                            ],

                            Expanded(
                              child: Text(
                                announcement.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  fontWeight: FontWeight.w800,
                                  color: dialogContext.appTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            if (announcement.author.isNotEmpty) ...[
                              Text(
                                announcement.author,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: dialogContext.appTextSecondary,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: dialogContext.appTextSecondary,
                                ),
                              ),

                              const SizedBox(width: 8),
                            ],

                            Text(
                              _formatDetailDate(announcement.publishedAt),
                              style: TextStyle(
                                fontSize: 9,
                                color: dialogContext.appTextSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Divider(height: 1, color: dialogContext.appBorder),

                        const SizedBox(height: 18),

                        Text(
                          announcement.body.isEmpty
                              ? '등록된 내용이 없습니다.'
                              : announcement.body,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.7,
                            color: dialogContext.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          _AnnouncementRow(
            announcement: visibleItems[index],
            onTap: () {
              _showAnnouncementDetail(context, visibleItems[index]);
            },
          ),

          if (index < visibleItems.length - 1)
            Divider(height: 1, thickness: 1, color: context.appBorder),
        ],
      ],
    );
  }
}

// ============================================================
// Announcement Row
// 홈: compact
// 전체보기: expanded
// ============================================================

class _AnnouncementRow extends StatelessWidget {
  final DashboardAnnouncement announcement;
  final bool expanded;
  final VoidCallback? onTap;

  const _AnnouncementRow({
    required this.announcement,
    this.expanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final important = announcement.isImportant;

    final markerColor = important ? AppColors.danger : context.appBrand;

    final horizontalPadding = expanded ? 16.0 : 12.0;
    final verticalPadding = expanded ? 11.0 : 8.0;

    final titleFontSize = expanded ? 10.8 : 9.5;
    final bodyFontSize = expanded ? 9.2 : 8.2;
    final dateFontSize = expanded ? 8.8 : 8.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // Marker
            // ====================================================
            Container(
              width: expanded ? 7 : 6,
              height: expanded ? 7 : 6,
              margin: EdgeInsets.only(top: expanded ? 6 : 5),
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: expanded ? 11 : 9),

            // ====================================================
            // Content
            // ====================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (important) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: expanded ? 6 : 5,
                            vertical: expanded ? 2.5 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '중요',
                            style: TextStyle(
                              fontSize: expanded ? 8 : 7.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ),

                        SizedBox(width: expanded ? 7 : 6),
                      ],

                      Expanded(
                        child: Text(
                          announcement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),

                      SizedBox(width: expanded ? 14 : 8),

                      Text(
                        _formatDate(announcement.publishedAt),
                        style: TextStyle(
                          fontSize: dateFontSize,
                          fontWeight: expanded
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  if (expanded && announcement.body.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      announcement.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        height: 1.45,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

String _formatDetailDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }

  final koreaTime = dateTime.toUtc().add(const Duration(hours: 9));

  final year = koreaTime.year.toString();

  final month = koreaTime.month.toString().padLeft(2, '0');

  final day = koreaTime.day.toString().padLeft(2, '0');

  final hour = koreaTime.hour.toString().padLeft(2, '0');

  final minute = koreaTime.minute.toString().padLeft(2, '0');

  return '$year.$month.$day $hour:$minute';
}
