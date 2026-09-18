import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../data/models/chat_models.dart';
import '../data/services/chat_service.dart';

// ============================================================
// STEP 1. 채팅방 Filter
// ============================================================

enum ChatRoomFilter { all, direct, group }

// ============================================================
// STEP 2. Chat Panel
// ============================================================

class ChatPanel extends StatefulWidget {
  final ChatService chatService;
  final ValueChanged<int>? onUnreadChanged;

  const ChatPanel({super.key, required this.chatService, this.onUnreadChanged});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _messageScrollController = ScrollController();

  Timer? _roomRefreshTimer;
  Timer? _messageRefreshTimer;

  List<ChatRoom> _rooms = [];
  List<ChatDoctor> _doctors = [];
  List<ChatMessage> _messages = [];

  ChatRoom? _selectedRoom;

  ChatRoomFilter _filter = ChatRoomFilter.all;

  bool _loadingRooms = true;
  bool _loadingConversation = false;
  bool _sending = false;
  bool _showRoomInfo = false;
  bool _connected = false;

  String? _error;

  // ============================================================
  // 현재 로그인 사용자 ID
  // AuthProvider가 로그인 시 이미 StaffUser를 보관하고 있음
  // ============================================================

  int? get _currentUserId {
    return context.read<AuthProvider>().currentUser?.id;
  }

  // ============================================================
  // STEP 3. Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    _roomRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadRooms(quiet: true);
    });
  }

  @override
  void dispose() {
    _roomRefreshTimer?.cancel();
    _messageRefreshTimer?.cancel();

    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    _messageController.dispose();
    _messageScrollController.dispose();

    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // 현재 로그인 사용자 확인
  // 별도 /staff/me 호출 없이 AuthProvider 사용
  // ============================================================

  Future<bool> _ensureIdentity() async {
    final currentUser = context.read<AuthProvider>().currentUser;

    if (currentUser == null) {
      debugPrint('[CHAT] 로그인 사용자 정보가 없습니다.');

      return false;
    }
    return true;
  }

  // ============================================================
  // STEP 4. Initial Data
  // AuthProvider의 로그인 사용자 정보 사용
  // /staff/me API는 호출하지 않음
  // ============================================================

  Future<void> _loadInitialData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingRooms = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw StateError('현재 로그인 의료진 정보를 찾을 수 없습니다.');
      }

      // ==========================================================
      // 채팅방 목록
      // ==========================================================

      final rooms = await widget.chatService.fetchRooms();

      // ==========================================================
      // 의료진 목록
      // 새 채팅 / 그룹 초대에서 사용
      // ==========================================================

      List<ChatDoctor> doctors = [];

      try {
        doctors = await widget.chatService.fetchDoctors();
      } catch (error) {
        debugPrint('[CHAT] doctors load failed: $error');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _rooms = rooms;

        _doctors = doctors
            .where(
              (doctor) => doctor.isActive && doctor.userId != currentUser.id,
            )
            .toList();

        _loadingRooms = false;
        _connected = true;
        _error = null;
      });

      _notifyUnread();
    } catch (error) {
      debugPrint('[CHAT] initial load failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRooms = false;
        _connected = false;
        _error = _errorText(error, '채팅 정보를 불러오지 못했습니다.');
      });
    }
  }

  // ============================================================
  // STEP 5. 채팅방 목록
  // ============================================================

  Future<void> _loadRooms({bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loadingRooms = true;
        _error = null;
      });
    }

    try {
      final rooms = await widget.chatService.fetchRooms();

      if (!mounted) {
        return;
      }

      setState(() {
        _rooms = rooms;
        _connected = true;
        _error = null;

        if (!quiet) {
          _loadingRooms = false;
        }
      });

      _notifyUnread();
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (!quiet) {
        setState(() {
          _loadingRooms = false;
          _error = _errorText(error, '채팅방을 불러오지 못했습니다.');
        });
      }
    }
  }

  int get _totalUnreadCount {
    return _rooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  void _notifyUnread() {
    widget.onUnreadChanged?.call(_totalUnreadCount);
  }

  // ============================================================
  // STEP 6. 채팅방 열기
  // identity를 먼저 확보한 뒤 대화 조회
  // ============================================================

  Future<void> _openRoom(ChatRoom room) async {
    _messageRefreshTimer?.cancel();

    setState(() {
      _selectedRoom = room;
      _messages = [];
      _showRoomInfo = false;
      _error = null;
    });

    // 내 메시지 판별에 필요한 로그인 사용자 정보
    await _ensureIdentity();

    if (!mounted) {
      return;
    }

    await _loadConversation(room.id);

    _messageRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadConversation(room.id, quiet: true);
    });
  }

  void _backToRooms() {
    _messageRefreshTimer?.cancel();

    setState(() {
      _selectedRoom = null;
      _messages = [];
      _showRoomInfo = false;
    });

    _loadRooms(quiet: true);
  }

  // ============================================================
  // STEP 7. 대화 조회 + 초대 자동 수락 + 읽음
  // ============================================================

  Future<void> _loadConversation(int roomId, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loadingConversation = true;
        _error = null;
      });
    }

    try {
      var room = await widget.chatService.fetchRoom(roomId);

      final invitedMembership = _findCurrentMembership(room);

      if (invitedMembership != null &&
          invitedMembership.status == 'INVITED' &&
          invitedMembership.id != null) {
        await widget.chatService.acceptInvite(
          roomId: roomId,
          membershipId: invitedMembership.id!,
        );

        room = await widget.chatService.fetchRoom(roomId);
      }

      final messages = await widget.chatService.fetchMessages(roomId);

      // ============================================================
      // 채팅방 읽음 처리
      // 현재 방의 마지막 메시지까지 읽음으로 기록
      // ============================================================

      final latestMessage = messages.isEmpty ? null : messages.last;

      final currentMembership = _findCurrentMembership(room);

      final lastReadMessageId = currentMembership?.lastReadMessageId;

      final shouldMarkRead =
          latestMessage != null &&
          (lastReadMessageId == null || lastReadMessageId < latestMessage.id);

      if (shouldMarkRead) {
        try {
          await widget.chatService.markRoomRead(
            roomId: roomId,
            messageId: latestMessage.id,
          );

          // 서버에서 갱신된 last_read_message_id 반영
          room = await widget.chatService.fetchRoom(roomId);
        } catch (_) {
          // 읽음 처리 실패가 대화 조회 전체를 막지는 않습니다.
        }
      }

      if (!mounted || _selectedRoom?.id != roomId) {
        return;
      }

      setState(() {
        _selectedRoom = room;
        _messages = messages;
        _loadingConversation = false;
        _connected = true;

        _rooms = _rooms.map((item) {
          if (item.id == roomId) {
            return item.copyWith(unreadCount: 0);
          }

          return item;
        }).toList();
      });

      _notifyUnread();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (!quiet) {
        setState(() {
          _loadingConversation = false;
          _error = _errorText(error, '대화 내용을 불러오지 못했습니다.');
        });
      }
    }
  }

  ChatMember? _findCurrentMembership(ChatRoom room) {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return null;
    }

    for (final member in room.members) {
      if (member.userId == currentUserId) {
        return member;
      }
    }

    return null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }

      final position = _messageScrollController.position.maxScrollExtent;

      _messageScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // STEP 8. 메시지 전송
  // ============================================================

  Future<void> _sendMessage() async {
    final room = _selectedRoom;

    final text = _messageController.text.trim();

    if (room == null || text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    _messageController.clear();

    try {
      await widget.chatService.sendMessage(roomId: room.id, text: text);

      await _loadConversation(room.id, quiet: true);

      await _loadRooms(quiet: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _messageController.text = text;

      setState(() {
        _error = _errorText(error, '메시지를 전송하지 못했습니다.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 9. 새 채팅 Dialog
  //
  // Dialog에서는 입력값만 선택합니다.
  // 실제 API 호출은 Dialog가 완전히 닫힌 뒤 실행합니다.
  // ============================================================

  Future<void> _openCreateRoomDialog() async {
    String roomType = 'DIRECT';
    String roomTitle = '';

    final selectedUserIds = <int>{};

    // ==========================================================
    // Dialog 결과만 받기
    // ==========================================================

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            final colorScheme = theme.colorScheme;

            final canSubmit =
                selectedUserIds.isNotEmpty &&
                (roomType != 'GROUP' || roomTitle.trim().isNotEmpty);

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              titlePadding: const EdgeInsets.fromLTRB(22, 18, 10, 4),
              contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '새 채팅',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();

                      await Future<void>.delayed(
                        const Duration(milliseconds: 100),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                height: 470,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // 개인 / 단체
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: _RoomTypeButton(
                            label: '개인',
                            icon: Icons.person_outline_rounded,
                            selected: roomType == 'DIRECT',
                            onTap: () {
                              setDialogState(() {
                                roomType = 'DIRECT';

                                roomTitle = '';

                                selectedUserIds.clear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RoomTypeButton(
                            label: '단체',
                            icon: Icons.groups_outlined,
                            selected: roomType == 'GROUP',
                            onTap: () {
                              setDialogState(() {
                                roomType = 'GROUP';

                                selectedUserIds.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // 그룹 채팅방 이름
                    // ==================================================
                    if (roomType == 'GROUP') ...[
                      const SizedBox(height: 14),
                      TextField(
                        maxLength: 150,
                        onChanged: (value) {
                          setDialogState(() {
                            roomTitle = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '채팅방 이름',
                          hintText: '예: 심장내과 협진팀',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    Text(
                      '의료진 선택',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // 의료진 목록
                    // ==================================================
                    Expanded(
                      child: _doctors.isEmpty
                          ? Center(
                              child: Text(
                                '선택 가능한 의료진이 없습니다.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.separated(
                                itemCount: _doctors.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: theme.dividerColor,
                                ),
                                itemBuilder: (context, index) {
                                  final doctor = _doctors[index];

                                  final selected = selectedUserIds.contains(
                                    doctor.userId,
                                  );

                                  return CheckboxListTile(
                                    value: selected,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    secondary: CircleAvatar(
                                      radius: 17,
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      doctor.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _doctorMeta(doctor),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onChanged: (_) {
                                      setDialogState(() {
                                        // ==================================
                                        // 개인 채팅
                                        // 한 명만 선택
                                        // ==================================

                                        if (roomType == 'DIRECT') {
                                          selectedUserIds
                                            ..clear()
                                            ..add(doctor.userId);

                                          return;
                                        }

                                        // ==================================
                                        // 단체 채팅
                                        // 여러 명 선택
                                        // ==================================

                                        if (selected) {
                                          selectedUserIds.remove(doctor.userId);
                                        } else {
                                          selectedUserIds.add(doctor.userId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 100),
                    );

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),

                FilledButton.icon(
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          final payload = <String, dynamic>{
                            'roomType': roomType,
                            'memberUserIds': selectedUserIds.toList(),
                            'title': roomType == 'GROUP'
                                ? roomTitle.trim()
                                : null,
                          };

                          // ==============================================
                          // 키보드 / TextField Overlay 먼저 종료
                          // ==============================================

                          FocusManager.instance.primaryFocus?.unfocus();

                          await Future<void>.delayed(
                            const Duration(milliseconds: 100),
                          );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          // ==============================================
                          // API 호출하지 않고 값만 반환
                          // ==============================================

                          Navigator.of(dialogContext).pop(payload);
                        },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text('채팅 시작'),
                ),
              ],
            );
          },
        );
      },
    );

    // ==========================================================
    // 취소
    // ==========================================================

    if (result == null || !mounted) {
      return;
    }

    // ==========================================================
    // Dialog Overlay가 완전히 빠질 시간을 줍니다.
    // ==========================================================

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) {
      return;
    }

    final selectedRoomType = result['roomType']?.toString() ?? 'DIRECT';

    final selectedMembers = List<int>.from(result['memberUserIds'] as List);

    final selectedTitle = result['title']?.toString();

    // ==========================================================
    // 여기서부터 실제 API 호출
    // ==========================================================

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.chatService.createRoom(
        roomType: selectedRoomType,
        memberUserIds: selectedMembers,
        title: selectedRoomType == 'GROUP' ? selectedTitle : null,
      );

      if (!mounted) {
        return;
      }

      // Dialog가 사라진 이후에 목록 갱신
      await _loadRooms();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _errorText(error, '채팅방을 만들지 못했습니다.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 10. 그룹 의료진 초대
  // ============================================================

  Future<void> _openInviteDialog() async {
    final room = _selectedRoom;

    if (room == null) {
      return;
    }

    final availableDoctors = _doctors.where((doctor) {
      return !room.members.any(
        (member) =>
            member.userId == doctor.userId &&
            member.status != 'LEFT' &&
            member.status != 'REMOVED',
      );
    }).toList();

    if (availableDoctors.isEmpty) {
      _showMessage('추가로 초대할 수 있는 의료진이 없습니다.');
      return;
    }

    int? selectedUserId;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('의료진 추가 초대'),
              content: SizedBox(
                width: 380,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: '의료진',
                    border: OutlineInputBorder(),
                  ),
                  items: availableDoctors
                      .map(
                        (doctor) => DropdownMenuItem<int>(
                          value: doctor.userId,
                          child: Text(
                            '${doctor.name} · ${doctor.departmentName}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) {
                          setDialogState(() {
                            selectedUserId = value;
                          });
                        },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () {
                          FocusScope.of(dialogContext).unfocus();

                          Navigator.pop(dialogContext);
                        },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: submitting || selectedUserId == null
                      ? null
                      : () async {
                          setDialogState(() {
                            submitting = true;
                          });

                          try {
                            await widget.chatService.inviteMember(
                              roomId: room.id,
                              userId: selectedUserId!,
                            );

                            if (!mounted || !dialogContext.mounted) {
                              return;
                            }

                            FocusScope.of(dialogContext).unfocus();

                            Navigator.pop(dialogContext);

                            await _loadRooms();
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _error = _errorText(error, '의료진을 초대하지 못했습니다.');
                            });

                            setDialogState(() {
                              submitting = false;
                            });
                          }
                        },
                  child: const Text('초대'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STEP 11. 채팅방 나가기
  // ============================================================

  Future<void> _leaveRoom() async {
    final room = _selectedRoom;

    if (room == null) {
      return;
    }

    final membership = _findCurrentMembership(room);

    if (membership?.id == null) {
      _showMessage('현재 참여자 정보를 확인할 수 없습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('채팅방 나가기'),
          content: Text('“${_roomTitle(room)}”에서 나갈까요?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        _sending = true;
      });

      await widget.chatService.leaveRoom(
        roomId: room.id,
        membershipId: membership!.id!,
      );

      if (!mounted) {
        return;
      }

      _backToRooms();

      await _loadRooms();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _errorText(error, '채팅방에서 나가지 못했습니다.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // STEP 12. Display Helper
  // ============================================================

  ChatDoctor? _doctorByUserId(int userId) {
    for (final doctor in _doctors) {
      if (doctor.userId == userId) {
        return doctor;
      }
    }

    return null;
  }

  String _memberName(ChatMember member) {
    final doctor = _doctorByUserId(member.userId);

    if (doctor != null && doctor.name.trim().isNotEmpty) {
      return doctor.name.trim();
    }

    final apiName = member.name.trim();

    if (apiName.isNotEmpty && apiName != '의료진') {
      return apiName;
    }

    if (member.username.trim().isNotEmpty) {
      return member.username.trim();
    }

    return '의료진 #${member.userId}';
  }

  String _memberDetail(ChatMember member) {
    final doctor = _doctorByUserId(member.userId);

    if (doctor != null) {
      final meta = _doctorMeta(doctor);

      if (meta.isNotEmpty) {
        return meta;
      }
    }

    final values = [
      member.departmentName,
      member.title,
    ].where((value) => value.trim().isNotEmpty).toList();

    if (values.isNotEmpty) {
      return values.join(' · ');
    }

    return member.role;
  }

  String _doctorMeta(ChatDoctor doctor) {
    return [
      doctor.departmentName,
      doctor.title,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String _roomTitle(ChatRoom room) {
    if (room.title.trim().isNotEmpty &&
        room.title != '1:1 채팅' &&
        room.title != '그룹 채팅') {
      return room.title.trim();
    }

    final names = room.members
        .where((member) => member.userId != _currentUserId)
        .map(_memberName)
        .toList();

    if (names.isNotEmpty) {
      return names.join(', ');
    }

    if (room.title.trim().isNotEmpty) {
      return room.title.trim();
    }

    return room.roomType == 'DIRECT' ? '개인 채팅' : '단체 채팅';
  }

  List<ChatRoom> get _filteredRooms {
    final keyword = _searchController.text.trim().toLowerCase();

    return _rooms.where((room) {
      final typeMatches = switch (_filter) {
        ChatRoomFilter.all => true,
        ChatRoomFilter.direct => room.roomType == 'DIRECT',
        ChatRoomFilter.group => room.roomType != 'DIRECT',
      };

      if (!typeMatches) {
        return false;
      }

      if (keyword.isEmpty) {
        return true;
      }

      final searchTarget =
          '${_roomTitle(room)} '
                  '${room.latestMessage?.text ?? ''}'
              .toLowerCase();

      return searchTarget.contains(keyword);
    }).toList();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final date = value.toLocal();

    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${two(date.month)}.${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String _errorText(Object error, String fallback) {
    final text = error.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    if (text.length > 250) {
      return fallback;
    }

    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  // ============================================================
  // STEP 13. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        left: false,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(left: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            children: [
              _buildHeader(),

              Divider(height: 1, color: theme.dividerColor),

              if (_error != null) _buildErrorBanner(),

              Expanded(
                child: _selectedRoom == null
                    ? _buildRoomList()
                    : _showRoomInfo
                    ? _buildRoomInfo()
                    : _buildConversation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 14. Panel Header
  // ============================================================

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final room = _selectedRoom;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            if (room != null)
              IconButton(
                tooltip: '채팅 목록',
                onPressed: _backToRooms,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else
              const SizedBox(width: 8),

            if (room == null)
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 21,
                color: colorScheme.primary,
              ),

            if (room == null) const SizedBox(width: 9),

            Expanded(
              child: room == null
                  ? Row(
                      children: [
                        Text(
                          '채팅',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _connected
                                ? const Color(0xFF2E9D70)
                                : colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          _connected ? '연결됨' : '연결 확인 중',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _roomTitle(room),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.roomType == 'DIRECT'
                              ? '개인 채팅'
                              : '단체 채팅 · ${room.members.length}명',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),

            if (room != null)
              IconButton(
                tooltip: '채팅방 정보',
                onPressed: () {
                  setState(() {
                    _showRoomInfo = !_showRoomInfo;
                  });
                },
                icon: Icon(
                  _showRoomInfo ? Icons.groups_rounded : Icons.groups_outlined,
                  color: colorScheme.primary,
                ),
              ),

            IconButton(
              tooltip: '닫기',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 15. Error Banner
  // ============================================================

  Widget _buildErrorBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _error ?? '',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            icon: const Icon(Icons.close_rounded, size: 16),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 16. Room List
  // ============================================================

  Widget _buildRoomList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rooms = _filteredRooms;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: _openCreateRoomDialog,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('새 채팅'),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '채팅방 또는 의료진 검색',
              prefixIcon: Icon(Icons.search_rounded, size: 19),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: _ChatFilterButton(
                  label: '전체',
                  selected: _filter == ChatRoomFilter.all,
                  onTap: () {
                    setState(() {
                      _filter = ChatRoomFilter.all;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ChatFilterButton(
                  label: '개인 채팅',
                  selected: _filter == ChatRoomFilter.direct,
                  onTap: () {
                    setState(() {
                      _filter = ChatRoomFilter.direct;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ChatFilterButton(
                  label: '단체 채팅',
                  selected: _filter == ChatRoomFilter.group,
                  onTap: () {
                    setState(() {
                      _filter = ChatRoomFilter.group;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Divider(height: 1, color: theme.dividerColor),

        Expanded(
          child: _loadingRooms
              ? const Center(child: CircularProgressIndicator())
              : rooms.isEmpty
              ? Center(
                  child: Text(
                    '표시할 채팅방이 없습니다.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      return _buildRoomTile(rooms[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRoomTile(ChatRoom room) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final unread = room.unreadCount;

    final time =
        room.latestMessage?.createdAt ?? room.updatedAt ?? room.createdAt;

    return Material(
      color: unread > 0
          ? colorScheme.primaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          _openRoom(room);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  room.roomType == 'DIRECT'
                      ? Icons.person_outline_rounded
                      : Icons.groups_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _roomTitle(room),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.latestMessage?.text.trim().isNotEmpty == true
                          ? room.latestMessage!.text
                          : '새 대화를 시작하세요.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDateTime(time),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (unread > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 21,
                        minHeight: 21,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 21),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 17. Conversation
  // ============================================================

  Widget _buildConversation() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: _loadingConversation
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? Center(
                  child: Text(
                    '아직 메시지가 없습니다.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _messageScrollController,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[index]);
                  },
                ),
        ),

        Divider(height: 1, color: theme.dividerColor),

        _buildComposer(),
      ],
    );
  }

  // ============================================================
  // 내 메시지 판별
  // ChatMessage.sender = Backend User ID
  // StaffUser.id       = Backend User ID
  // ============================================================

  bool _isMyMessage(ChatMessage message) {
    final currentUserId = _currentUserId;

    final senderId = message.senderId;

    if (currentUserId == null || senderId == null) {
      return false;
    }

    return senderId == currentUserId;
  }

  // ============================================================
  // STEP. 내 메시지를 아직 읽지 않은 참여자 수
  //
  // 개인 채팅:
  // 1 = 상대방이 아직 안 읽음
  // 0 = 상대방이 읽음
  //
  // 단체 채팅:
  // 3, 2, 1 = 아직 안 읽은 참여자 수
  // 0 = 모두 읽음
  // ============================================================

  int _unreadRecipientCount(ChatMessage message) {
    if (!_isMyMessage(message)) {
      return 0;
    }

    final room = _selectedRoom;
    final currentUserId = _currentUserId;

    if (room == null || currentUserId == null) {
      return 0;
    }

    return room.members.where((member) {
      // 내 자신 제외
      if (member.userId == currentUserId) {
        return false;
      }

      // 이미 나간 참여자 제외
      final status = member.status.toUpperCase();

      if (status == 'LEFT' || status == 'REMOVED') {
        return false;
      }

      final lastReadMessageId = member.lastReadMessageId;

      // 한 번도 안 읽었거나
      // 이 메시지보다 이전까지만 읽음
      return lastReadMessageId == null || lastReadMessageId < message.id;
    }).length;
  }
  // ============================================================
  // STEP. Message Bubble
  // 내 메시지 = 오른쪽 / 상대방 = 왼쪽
  // ============================================================

  Widget _buildMessage(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;

    final mine = _isMyMessage(message);

    final doctor = message.senderId == null
        ? null
        : _doctorByUserId(message.senderId!);

    final senderName = mine
        ? '나'
        : doctor?.name.trim().isNotEmpty == true
        ? doctor!.name
        : message.senderName != '의료진' && message.senderName.trim().isNotEmpty
        ? message.senderName
        : message.senderId != null
        ? '의료진 #${message.senderId}'
        : '의료진';
    final bubbleColor = mine
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final bubbleTextColor = mine
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(13),
                  topRight: const Radius.circular(13),
                  bottomLeft: Radius.circular(mine ? 13 : 3),
                  bottomRight: Radius.circular(mine ? 3 : 13),
                ),
              ),
              child: Text(
                message.isDeleted ? '삭제된 메시지입니다.' : message.text,
                style: TextStyle(
                  color: bubbleTextColor,
                  fontSize: 12,
                  height: 1.45,
                  fontStyle: message.isDeleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mine) ...[
                    Builder(
                      builder: (context) {
                        final unreadCount = _unreadRecipientCount(message);

                        return Text(
                          unreadCount > 0 ? '$unreadCount' : '읽음',
                          style: TextStyle(
                            color: unreadCount > 0
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 5),
                  ],

                  Text(
                    _formatDateTime(message.createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 18. Message Composer
  // ============================================================

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: '메시지 입력',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: _sending || _messageController.text.trim().isEmpty
                  ? null
                  : _sendMessage,
              child: _sending
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 19. Room Info
  // ============================================================

  Widget _buildRoomInfo() {
    final room = _selectedRoom!;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final membership = _findCurrentMembership(room);

    final canInvite = room.roomType != 'DIRECT' && membership?.role == 'OWNER';

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  room.roomType == 'DIRECT'
                      ? Icons.person_outline_rounded
                      : Icons.groups_outlined,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _roomTitle(room),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${room.members.length}명의 참여자',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Text(
                '참여자',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${room.members.length}명',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ...room.members.map((member) {
          final mine = member.userId == _currentUserId;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            title: Text(
              mine ? '나' : _memberName(member),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _memberDetail(member),
              style: const TextStyle(fontSize: 10),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.role == 'OWNER' ? '방장' : '참여자',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        if (canInvite)
          OutlinedButton.icon(
            onPressed: _openInviteDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('의료진 추가 초대'),
          ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: _sending || membership?.id == null ? null : _leaveRoom,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('채팅방 나가기'),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 20. Filter Button
// ============================================================

class _ChatFilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChatFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: selected
          ? FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: onTap,
              child: Text(label, style: const TextStyle(fontSize: 10)),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: onTap,
              child: Text(label, style: const TextStyle(fontSize: 10)),
            ),
    );
  }
}

// ============================================================
// STEP 21. Room Type Button
// ============================================================

class _RoomTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoomTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: selected
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label),
            ),
    );
  }
}

// ============================================================
// STEP 22. Right Chat Panel 열기
// 현재 화면 위에 우측에서 Slide
// Router 이동 없음
// ============================================================

Future<void> showChatPanel({
  required BuildContext context,
  required ChatService chatService,
  ValueChanged<int>? onUnreadChanged,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '채팅 닫기',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      final screenWidth = MediaQuery.sizeOf(context).width;

      final width = screenWidth < 650
          ? screenWidth
          : math.min(470.0, screenWidth * 0.42);

      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: ChatPanel(
            chatService: chatService,
            onUnreadChanged: onUnreadChanged,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
