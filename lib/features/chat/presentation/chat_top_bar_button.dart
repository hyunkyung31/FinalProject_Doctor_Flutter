import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../data/services/chat_service.dart';
import 'chat_panel.dart';

// ============================================================
// STEP 1. Top Bar Chat Button
// 실제 unread badge + 우측 Chat Panel
// ============================================================

class ChatTopBarButton extends StatefulWidget {
  final bool enabled;

  const ChatTopBarButton({super.key, required this.enabled});

  @override
  State<ChatTopBarButton> createState() => _ChatTopBarButtonState();
}

class _ChatTopBarButtonState extends State<ChatTopBarButton> {
  ChatService? _chatService;

  Timer? _unreadTimer;

  int _unreadCount = 0;

  bool _loadingUnread = false;
  bool _panelOpened = false;

  // ============================================================
  // STEP 2. Lifecycle
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_chatService != null) {
      return;
    }

    final auth = context.read<AuthProvider>();

    _chatService = ChatService(apiClient: auth.authService.apiClient);

    if (widget.enabled) {
      _startUnreadPolling();
    }
  }

  @override
  void didUpdateWidget(covariant ChatTopBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled == widget.enabled) {
      return;
    }

    if (widget.enabled) {
      _startUnreadPolling();
    } else {
      _unreadTimer?.cancel();

      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // STEP 3. Unread Polling
  // Panel이 닫혀 있어도 상단 Badge 갱신
  // ============================================================

  void _startUnreadPolling() {
    _unreadTimer?.cancel();

    _refreshUnread();

    _unreadTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshUnread();
    });
  }

  Future<void> _refreshUnread() async {
    final service = _chatService;

    if (!widget.enabled || service == null || _loadingUnread) {
      return;
    }

    _loadingUnread = true;

    try {
      final rooms = await service.fetchRooms();

      final total = rooms.fold<int>(0, (sum, room) => sum + room.unreadCount);

      if (!mounted) {
        return;
      }

      if (_unreadCount != total) {
        setState(() {
          _unreadCount = total;
        });
      }
    } catch (_) {
      // 상단 Badge 갱신 실패가 앱 전체 UI를 막지 않도록
      // 조용히 다음 polling에서 재시도합니다.
    } finally {
      _loadingUnread = false;
    }
  }

  // ============================================================
  // STEP 4. Panel Open
  // ============================================================

  Future<void> _openChat() async {
    final service = _chatService;

    if (!widget.enabled || service == null || _panelOpened) {
      return;
    }

    _panelOpened = true;

    try {
      await showChatPanel(
        context: context,
        chatService: service,
        onUnreadChanged: (count) {
          if (!mounted) {
            return;
          }

          if (_unreadCount != count) {
            setState(() {
              _unreadCount = count;
            });
          }
        },
      );
    } finally {
      _panelOpened = false;

      if (mounted) {
        _refreshUnread();
      }
    }
  }

  // ============================================================
  // STEP 5. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final badgeText = _unreadCount > 99 ? '99+' : '$_unreadCount';

    return IconButton(
      tooltip: '채팅',
      onPressed: widget.enabled ? _openChat : null,
      icon: Badge(
        label: Text(
          badgeText,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),

        // unread 0이면 Badge 자체 숨김
        isLabelVisible: widget.enabled && _unreadCount > 0,

        backgroundColor: colorScheme.error,

        textColor: colorScheme.onError,

        child: Icon(
          Icons.chat_bubble_outline_rounded,
          color: widget.enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
