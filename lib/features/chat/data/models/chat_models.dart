// ============================================================
// STEP 1. 공통 Parsing Helper
// Backend snake_case / React camelCase 양쪽 대응
// ============================================================

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text = value?.toString().trim().toLowerCase();

  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }

  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }

  return fallback;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  return value.toString();
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value.toLocal();
  }

  return DateTime.tryParse(value.toString())?.toLocal();
}

Map<String, dynamic>? _parseMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

// nullable Map에서 안전하게 값 꺼내기
dynamic _mapValue(Map<String, dynamic>? map, String key) {
  if (map == null) {
    return null;
  }

  return map[key];
}

// user 값이
// 1) 숫자 user id
// 2) {id: ...} 형태 Map
// 둘 다 대응
dynamic _idFromRawUser(dynamic value) {
  if (value is Map) {
    return value['id'] ?? value['user_id'] ?? value['userId'];
  }

  return value;
}

// ============================================================
// STEP 3. 의료진 목록 Model
// ============================================================

class ChatDoctor {
  final int id;
  final int userId;
  final String name;
  final String departmentName;
  final String title;
  final bool isActive;

  const ChatDoctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.departmentName,
    required this.title,
    required this.isActive,
  });

  factory ChatDoctor.fromJson(Map<String, dynamic> json) {
    final user = _parseMap(json['user']);

    final staffProfile = _parseMap(
      json['staff_profile'] ?? json['staffProfile'],
    );

    final department = _parseMap(json['department']);

    final userId = _parseInt(
      json['user_id'] ??
          json['userId'] ??
          _idFromRawUser(json['user']) ??
          _mapValue(staffProfile, 'staff_id') ??
          json['staff_id'] ??
          json['id'],
    );

    return ChatDoctor(
      id: _parseInt(
        json['id'] ?? json['doctor_id'] ?? _mapValue(staffProfile, 'doctor_id'),
      ),
      userId: userId,
      name: _parseString(
        json['name'] ??
            json['full_name'] ??
            json['fullName'] ??
            json['user_name'] ??
            json['userName'] ??
            _mapValue(user, 'name') ??
            _mapValue(user, 'full_name') ??
            _mapValue(staffProfile, 'name') ??
            _mapValue(user, 'username'),
        fallback: userId > 0 ? '의료진 #$userId' : '의료진',
      ),
      departmentName: _parseString(
        json['department_name'] ??
            json['departmentName'] ??
            _mapValue(department, 'name') ??
            _mapValue(staffProfile, 'department_name') ??
            _mapValue(staffProfile, 'departmentName'),
      ),
      title: _parseString(
        json['title'] ?? json['position'] ?? _mapValue(staffProfile, 'title'),
      ),
      isActive: _parseBool(
        json['is_active'] ??
            json['isActive'] ??
            json['active'] ??
            _mapValue(staffProfile, 'is_active'),
        fallback: true,
      ),
    );
  }
}

// ============================================================
// STEP 4. 채팅방 참여자 Model
//
// 실제 Backend 구조:
// id
// user
// user_name
// department_name
// title
// staff_profile
// member_role
// membership_status
// ============================================================

class ChatMember {
  final int? id;
  final int userId;
  final String name;
  final String username;
  final String departmentName;
  final String title;
  final String role;
  final String status;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;

  const ChatMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.departmentName,
    required this.title,
    required this.role,
    required this.status,
    required this.lastReadMessageId,
    required this.lastReadAt,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    final user = _parseMap(json['user']);

    final staffProfile = _parseMap(
      json['staff_profile'] ?? json['staffProfile'],
    );

    final department = _parseMap(json['department']);

    final userId = _parseInt(
      json['user_id'] ??
          json['userId'] ??
          _idFromRawUser(json['user']) ??
          _mapValue(staffProfile, 'staff_id'),
    );

    return ChatMember(
      id: _parseNullableInt(
        json['id'] ?? json['membership_id'] ?? json['membershipId'],
      ),
      userId: userId,
      name: _parseString(
        json['user_name'] ??
            json['userName'] ??
            json['name'] ??
            json['full_name'] ??
            json['fullName'] ??
            _mapValue(user, 'name') ??
            _mapValue(user, 'full_name') ??
            _mapValue(staffProfile, 'name'),
        fallback: userId > 0 ? '의료진 #$userId' : '의료진',
      ),
      username: _parseString(json['username'] ?? _mapValue(user, 'username')),
      departmentName: _parseString(
        json['department_name'] ??
            json['departmentName'] ??
            _mapValue(department, 'name') ??
            _mapValue(staffProfile, 'department_name') ??
            _mapValue(staffProfile, 'departmentName'),
      ),
      title: _parseString(
        json['title'] ?? json['position'] ?? _mapValue(staffProfile, 'title'),
      ),
      role: _parseString(
        json['member_role'] ?? json['memberRole'] ?? json['role'],
        fallback: 'MEMBER',
      ).toUpperCase(),
      status: _parseString(
        json['membership_status'] ?? json['membershipStatus'] ?? json['status'],
        fallback: 'ACTIVE',
      ).toUpperCase(),
      lastReadMessageId: _parseNullableInt(
        json['last_read_message_id'] ?? json['lastReadMessageId'],
      ),
      lastReadAt: _parseDateTime(json['last_read_at'] ?? json['lastReadAt']),
    );
  }
}

// ============================================================
// STEP 5. 채팅 메시지 Model
// ============================================================

class ChatMessage {
  final int id;
  final int? senderId;
  final String senderName;
  final String text;
  final String type;
  final bool isDeleted;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.isDeleted,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderRaw =
        json['sender'] ?? json['sender_user'] ?? json['senderUser'];

    final sender = _parseMap(senderRaw);

    final staffProfile = _parseMap(
      json['sender_staff_profile'] ?? json['senderStaffProfile'],
    );

    final senderId = _parseNullableInt(
      json['sender_id'] ??
          json['senderId'] ??
          _idFromRawUser(senderRaw) ??
          _mapValue(staffProfile, 'staff_id'),
    );

    final deletedAt = json['deleted_at'] ?? json['deletedAt'];

    final isDeleted =
        deletedAt != null ||
        _parseBool(json['is_deleted'] ?? json['isDeleted'] ?? json['deleted']);

    return ChatMessage(
      id: _parseInt(json['id']),
      senderId: senderId,
      senderName: _parseString(
        json['sender_name'] ??
            json['senderName'] ??
            json['user_name'] ??
            _mapValue(sender, 'name') ??
            _mapValue(sender, 'full_name') ??
            _mapValue(sender, 'username') ??
            _mapValue(staffProfile, 'name'),
        fallback: senderId != null && senderId > 0 ? '의료진 #$senderId' : '의료진',
      ),
      text: _parseString(
        json['text'] ??
            json['message_text'] ??
            json['messageText'] ??
            json['content'],
      ),
      type: _parseString(
        json['type'] ?? json['message_type'] ?? json['messageType'],
        fallback: 'TEXT',
      ).toUpperCase(),
      isDeleted: isDeleted,
      createdAt: _parseDateTime(
        json['created_at'] ??
            json['createdAt'] ??
            json['sent_at'] ??
            json['sentAt'],
      ),
    );
  }
}

// ============================================================
// STEP 6. 채팅방 Model
//
// 실제 Backend 목록 응답:
//
// {
//   room: {
//     id: 5,
//     room_type: GROUP,
//     title: 협진,
//     ...
//   },
//   members: [
//     ...
//   ]
// }
// ============================================================

class ChatRoom {
  final int id;
  final String roomType;
  final String title;
  final List<ChatMember> members;
  final ChatMessage? latestMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatRoom({
    required this.id,
    required this.roomType,
    required this.title,
    required this.members,
    required this.latestMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // ==========================================================
    // 실제 서버의 nested room 처리
    // ==========================================================

    final nestedRoom = _parseMap(json['room']);

    final Map<String, dynamic> roomData;

    if (nestedRoom != null) {
      roomData = nestedRoom;
    } else {
      roomData = json;
    }

    // ==========================================================
    // Members
    // ==========================================================

    final memberData =
        json['members'] ??
        json['room_members'] ??
        json['roomMembers'] ??
        roomData['members'];

    final List<ChatMember> members;

    if (memberData is List) {
      members = memberData
          .whereType<Map>()
          .map((item) => ChatMember.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else {
      members = <ChatMember>[];
    }

    // ==========================================================
    // Latest Message
    // ==========================================================

    final latestData =
        json['latest_message'] ??
        json['latestMessage'] ??
        json['last_message'] ??
        json['lastMessage'] ??
        roomData['latest_message'] ??
        roomData['latestMessage'] ??
        roomData['last_message'] ??
        roomData['lastMessage'];

    ChatMessage? latestMessage;

    if (latestData is Map) {
      latestMessage = ChatMessage.fromJson(
        Map<String, dynamic>.from(latestData),
      );
    }

    // ==========================================================
    // Room 기본 정보
    // ==========================================================

    final roomId = _parseInt(
      roomData['id'] ?? json['room_id'] ?? json['roomId'],
    );

    final roomType = _parseString(
      roomData['room_type'] ??
          roomData['roomType'] ??
          roomData['type'] ??
          json['room_type'] ??
          json['roomType'],
      fallback: 'DIRECT',
    ).toUpperCase();

    final title = _parseString(roomData['title'] ?? json['title']);

    final unreadCount = _parseInt(
      json['unread_count'] ??
          json['unreadCount'] ??
          json['unread'] ??
          roomData['unread_count'] ??
          roomData['unreadCount'],
    );

    final createdAt = _parseDateTime(
      roomData['created_at'] ??
          roomData['createdAt'] ??
          json['created_at'] ??
          json['createdAt'],
    );

    final updatedAt = _parseDateTime(
      roomData['updated_at'] ??
          roomData['updatedAt'] ??
          json['updated_at'] ??
          json['updatedAt'],
    );

    return ChatRoom(
      id: roomId,
      roomType: roomType,
      title: title,
      members: members,
      latestMessage: latestMessage,
      unreadCount: unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ChatRoom copyWith({
    String? roomType,
    String? title,
    List<ChatMember>? members,
    ChatMessage? latestMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id,
      roomType: roomType ?? this.roomType,
      title: title ?? this.title,
      members: members ?? this.members,
      latestMessage: latestMessage ?? this.latestMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
