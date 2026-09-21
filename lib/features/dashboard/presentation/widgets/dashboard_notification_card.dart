import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme_context.dart';
import '../../../notifications/data/models/notification_item.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';

class DashboardNotificationCard extends StatefulWidget {
  final int refreshVersion;

  const DashboardNotificationCard({super.key, required this.refreshVersion});

  @override
  State<DashboardNotificationCard> createState() =>
      _DashboardNotificationCardState();
}

class _DashboardNotificationCardState extends State<DashboardNotificationCard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshVersion != widget.refreshVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh();
      });
    }
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    context.read<NotificationProvider>().refresh();
  }

  void _openNotificationPanel() {
    context.read<NotificationProvider>().refresh();

    showNotificationPanel(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    final notifications = provider.notifications.take(3).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            unreadCount: provider.unreadCount,
            totalCount: provider.total,
            onViewAll: _openNotificationPanel,
          ),

          Divider(height: 1, color: context.appBorder),

          if (provider.isLoading && notifications.isEmpty)
            const SizedBox(
              height: 136,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (provider.error != null && notifications.isEmpty)
            _ErrorBody(onRetry: _refresh)
          else if (notifications.isEmpty)
            const _EmptyBody()
          else
            ...notifications.map(
              (item) =>
                  _NotificationRow(item: item, onTap: _openNotificationPanel),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback onViewAll;

  const _Header({
    required this.unreadCount,
    required this.totalCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appBrand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 16,
              color: context.appBrand,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 알림',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  unreadCount > 0
                      ? '미확인 $unreadCount건 · 전체 $totalCount건'
                      : '미확인 없음 · 전체 $totalCount건',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: onViewAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '전체보기',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isRead
          ? Colors.transparent
          : context.appBrand.withValues(alpha: 0.035),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.appBrand.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForType(item.referenceType),
                  size: 15,
                  color: context.appBrand,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _formatTime(item.notificationCreatedAt),
                          style: TextStyle(
                            fontSize: 8,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (!item.isRead) ...[
                const SizedBox(width: 7),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: context.appBrand,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 28,
              color: context.appTextSecondary,
            ),
            const SizedBox(height: 7),
            Text(
              '표시할 알림이 없습니다.',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '알림을 불러오지 못했습니다.',
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도', style: TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type.toUpperCase()) {
    case 'CONSULTATION':
      return Icons.groups_2_outlined;

    case 'CHAT_MESSAGE':
      return Icons.chat_bubble_outline_rounded;

    case 'AI':
    case 'AI_ANALYSIS':
      return Icons.auto_awesome_outlined;

    case 'EXAMINATION':
      return Icons.science_outlined;

    case 'RESERVATION':
    case 'APPOINTMENT':
      return Icons.calendar_today_outlined;

    case 'REPORT':
      return Icons.description_outlined;

    default:
      return Icons.notifications_none_rounded;
  }
}

String _formatTime(DateTime value) {
  final koreaTime = value.toUtc().add(const Duration(hours: 9));

  final month = koreaTime.month.toString().padLeft(2, '0');

  final day = koreaTime.day.toString().padLeft(2, '0');

  final hour = koreaTime.hour.toString().padLeft(2, '0');

  final minute = koreaTime.minute.toString().padLeft(2, '0');

  return '$month.$day $hour:$minute';
}
