import 'dart:math';

import '../../../../core/network/api_client.dart';
import '../models/chat_models.dart';

// ============================================================
// STEP 1. Chat API Paths
// ============================================================

class ChatApiPaths {
  static const String doctors = '/doctors/';

  static const String rooms = '/staff/chat-rooms/';

  static String room(int roomId) => '/staff/chat-rooms/$roomId/';

  static String messages(int roomId) => '/staff/chat-rooms/$roomId/messages/';

  static String members(int roomId) => '/staff/chat-rooms/$roomId/members/';

  static String readRoom(int roomId) => '/staff/chat-rooms/$roomId/read/';

  static String acceptMember(int roomId, int membershipId) =>
      '/staff/chat-rooms/$roomId/members/'
      '$membershipId/accept/';

  static String leaveMember(int roomId, int membershipId) =>
      '/staff/chat-rooms/$roomId/members/'
      '$membershipId/';

  static String checkMessage(int messageId) =>
      '/staff/chat-messages/$messageId/check/';
}

// ============================================================
// STEP 2. Chat Service
// ============================================================

class ChatService {
  final ApiClient apiClient;

  ChatService({required this.apiClient});

  // ==========================================================
  // 의료진 목록
  // GET /doctors/
  // ==========================================================

  Future<List<ChatDoctor>> fetchDoctors() async {
    final response = await apiClient.dio.get(ChatApiPaths.doctors);

    final items = _unwrapList(response.data);

    return items
        .whereType<Map>()
        .map((item) => ChatDoctor.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ==========================================================
  // 채팅방 목록
  // GET /staff/chat-rooms/
  // ==========================================================

  Future<List<ChatRoom>> fetchRooms() async {
    final response = await apiClient.dio.get(ChatApiPaths.rooms);

    final items = _unwrapList(response.data);

    final rooms = items
        .whereType<Map>()
        .map((item) => ChatRoom.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    rooms.sort((a, b) {
      final aDate =
          a.latestMessage?.createdAt ??
          a.updatedAt ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate =
          b.latestMessage?.createdAt ??
          b.updatedAt ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return rooms;
  }

  // ==========================================================
  // 채팅방 상세
  // GET /staff/chat-rooms/{id}/
  // ==========================================================

  Future<ChatRoom> fetchRoom(int roomId) async {
    final response = await apiClient.dio.get(ChatApiPaths.room(roomId));

    final data = _unwrapMap(response.data, responseName: '채팅방 상세');

    return ChatRoom.fromJson(data);
  }

  // ==========================================================
  // 메시지 목록
  // GET /staff/chat-rooms/{id}/messages/
  // ==========================================================

  Future<List<ChatMessage>> fetchMessages(int roomId) async {
    final response = await apiClient.dio.get(
      ChatApiPaths.messages(roomId),
      queryParameters: {'size': 100},
    );

    final items = _unwrapList(response.data);

    final messages = items
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    messages.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return aDate.compareTo(bDate);
    });

    return messages;
  }

  // ============================================================
  // 채팅방 읽음 처리
  // POST /staff/chat-rooms/{roomId}/read/
  // ============================================================

  Future<void> markRoomRead({
    required int roomId,
    required int messageId,
  }) async {
    await apiClient.dio.post(
      ChatApiPaths.readRoom(roomId),
      data: {'message_id': messageId},
    );
  }

  // ============================================================
  // STEP. Client Message UUID 생성
  // 별도 package 없이 UUID v4 형식 생성
  // ============================================================

  String _createClientMessageId() {
    final random = Random.secure();

    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // UUID v4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // RFC 4122 variant
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  // ==========================================================
  // 메시지 전송
  // POST /staff/chat-rooms/{id}/messages/
  // ==========================================================

  Future<void> sendMessage({required int roomId, required String text}) async {
    final clientMessageId = _createClientMessageId();

    await apiClient.dio.post(
      ChatApiPaths.messages(roomId),
      data: {
        'client_message_id': clientMessageId,
        'type': 'TEXT',
        'text': text.trim(),
      },
    );
  }

  // ==========================================================
  // 새 채팅방
  // POST /staff/chat-rooms/
  // ==========================================================

  Future<ChatRoom?> createRoom({
    required String roomType,
    required List<int> memberUserIds,
    String? title,
  }) async {
    final response = await apiClient.dio.post(
      ChatApiPaths.rooms,
      data: {
        'type': roomType,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'members': memberUserIds,
      },
    );

    if (response.data == null) {
      return null;
    }

    final data = _tryUnwrapMap(response.data);

    if (data == null) {
      return null;
    }

    return ChatRoom.fromJson(data);
  }

  // ==========================================================
  // 그룹 채팅 의료진 초대
  // POST /staff/chat-rooms/{id}/members/
  // ==========================================================

  Future<void> inviteMember({required int roomId, required int userId}) async {
    await apiClient.dio.post(
      ChatApiPaths.members(roomId),
      data: {'user_id': userId, 'role': 'MEMBER'},
    );
  }

  // ==========================================================
  // 초대 수락
  // POST /staff/chat-rooms/{id}/members/{memberId}/accept/
  // ==========================================================

  Future<void> acceptInvite({
    required int roomId,
    required int membershipId,
  }) async {
    await apiClient.dio.post(ChatApiPaths.acceptMember(roomId, membershipId));
  }

  // ==========================================================
  // 채팅방 나가기
  // DELETE /staff/chat-rooms/{id}/members/{memberId}/
  // ==========================================================

  Future<void> leaveRoom({
    required int roomId,
    required int membershipId,
  }) async {
    await apiClient.dio.delete(ChatApiPaths.leaveMember(roomId, membershipId));
  }

  // ==========================================================
  // 응답 Parsing
  // ==========================================================

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) {
      return raw;
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      final candidates = [map['results'], map['items'], map['data']];

      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate;
        }

        if (candidate is Map) {
          final nested = Map<String, dynamic>.from(candidate);

          final nestedList = nested['results'] ?? nested['items'];

          if (nestedList is List) {
            return nestedList;
          }
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _unwrapMap(dynamic raw, {required String responseName}) {
    final result = _tryUnwrapMap(raw);

    if (result == null) {
      throw FormatException('$responseName 응답 형식이 올바르지 않습니다.');
    }

    return result;
  }

  Map<String, dynamic>? _tryUnwrapMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(raw);

    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }

    if (map['result'] is Map) {
      return Map<String, dynamic>.from(map['result'] as Map);
    }

    return map;
  }
}
