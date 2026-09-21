import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/presentation/chat_panel.dart';
import '../../data/models/notification_item.dart';
import '../../providers/notification_provider.dart';

void showNotificationPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '알림 닫기',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SafeArea(child: _NotificationPanel()),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(position: slideAnimation, child: child);
    },
  );
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 410,
        margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(-4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _NotificationHeader(
              unreadCount: provider.unreadCount,
              onReadAll: provider.markAllAsRead,
              onClose: () {
                Navigator.of(context).pop();
              },
            ),

            Divider(height: 1, color: theme.dividerColor),

            Expanded(child: _NotificationBody(provider: provider)),
          ],
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final Future<bool> Function() onReadAll;
  final VoidCallback onClose;

  const _NotificationHeader({
    required this.unreadCount,
    required this.onReadAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 19,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  unreadCount > 0 ? '읽지 않은 알림 $unreadCount건' : '새로운 알림이 없습니다.',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                onReadAll();
              },
              child: const Text('모두 읽음', style: TextStyle(fontSize: 10)),
            ),

          IconButton(
            tooltip: '닫기',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  final NotificationProvider provider;

  const _NotificationBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return _NotificationError(
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.notifications.isEmpty) {
      return const _NotificationEmpty();
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.notifications.length,
        separatorBuilder: (context, index) {
          return Divider(
            height: 1,
            indent: 66,
            color: Theme.of(context).dividerColor,
          );
        },
        itemBuilder: (context, index) {
          final item = provider.notifications[index];

          return _NotificationRow(
            item: item,
            onTap: () async {
              final referenceType = item.referenceType.toUpperCase();

              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);

              ChatService? chatService;

              if (referenceType == 'CHAT_MESSAGE') {
                final auth = context.read<AuthProvider>();

                chatService = ChatService(
                  apiClient: auth.authService.apiClient,
                );
              }

              final success = await provider.markAsRead(item);

              if (!context.mounted) {
                return;
              }

              if (!success) {
                return;
              }

              // 채팅 알림
              // 페이지 이동 없이 현재 화면 위에 Chat Panel 표시
              if (referenceType == 'CHAT_MESSAGE' && chatService != null) {
                navigator.pop();

                // 알림 패널 닫기 애니메이션 완료 후
                // 채팅 패널을 열어 패널이 겹치지 않도록 처리
                await Future<void>.delayed(const Duration(milliseconds: 220));

                if (!navigator.mounted) {
                  return;
                }

                await showChatPanel(
                  context: navigator.context,
                  chatService: chatService,
                );

                return;
              }

              // 채팅 외 알림은 실제 Router 이동
              final route = _notificationRoute(item);

              if (route == null) {
                return;
              }

              navigator.pop();

              router.go(route);
            },
          );
        },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: item.isRead
          ? Colors.transparent
          : colorScheme.primary.withValues(alpha: 0.035),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationTypeIcon(type: item.notificationType),

              const SizedBox(width: 12),

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
                              fontSize: 11.5,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),

                        if (!item.isRead)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Text(
                          _typeLabel(item.notificationType),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          _formatDateTime(item.notificationCreatedAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTypeIcon extends StatelessWidget {
  final String type;

  const _NotificationTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconForType(type), size: 18, color: colorScheme.primary),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 10),

          Text(
            '표시할 알림이 없습니다.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NotificationError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 11, color: colorScheme.error),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('다시 시도'),
          ),
        ],
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

String _typeLabel(String type) {
  switch (type.toUpperCase()) {
    case 'CONSULTATION':
      return '협진';

    case 'CHAT_MESSAGE':
      return '채팅';

    case 'AI':
    case 'AI_ANALYSIS':
      return 'AI';

    case 'EXAMINATION':
      return '검사';

    case 'RESERVATION':
    case 'APPOINTMENT':
      return '예약';

    case 'REPORT':
      return '보고서';

    default:
      return '알림';
  }
}

String _formatDateTime(DateTime dateTime) {
  final koreaTime = dateTime.toUtc().add(const Duration(hours: 9));

  final month = koreaTime.month.toString().padLeft(2, '0');

  final day = koreaTime.day.toString().padLeft(2, '0');

  final hour = koreaTime.hour.toString().padLeft(2, '0');

  final minute = koreaTime.minute.toString().padLeft(2, '0');

  return '$month.$day $hour:$minute';
}

String? _notificationRoute(NotificationItem item) {
  switch (item.referenceType.toUpperCase()) {
    case 'CONSULTATION':
      return AppRoutes.consult;

    default:
      return null;
  }
}
