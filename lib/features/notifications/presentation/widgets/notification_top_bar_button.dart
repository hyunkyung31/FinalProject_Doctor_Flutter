import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import 'notification_panel.dart';

class NotificationTopBarButton extends StatefulWidget {
  const NotificationTopBarButton({super.key});

  @override
  State<NotificationTopBarButton> createState() =>
      _NotificationTopBarButtonState();
}

class _NotificationTopBarButtonState extends State<NotificationTopBarButton> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    final unreadCount = notificationProvider.unreadCount;

    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: '알림',
      onPressed: () {
        context.read<NotificationProvider>().refresh();

        showNotificationPanel(context);
      },
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
        child: Icon(
          Icons.notifications_none_rounded,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
