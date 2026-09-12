// ============================================================
// STEP 1. Staff Schedule Model
// ============================================================

class StaffSchedule {
  final int id;
  final int user;
  final String title;
  final String scheduleType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? description;
  final bool isAllDay;
  final String? color;
  final String status;

  const StaffSchedule({
    required this.id,
    required this.user,
    required this.title,
    required this.scheduleType,
    required this.startsAt,
    required this.endsAt,
    required this.description,
    required this.isAllDay,
    required this.color,
    required this.status,
  });

  // ==========================================================
  // 서버 DateTime Parsing
  //
  // 서버:
  // 2026-09-11T08:30:00+09:00
  //
  // 의료진 앱에서는 서버가 내려준 한국 시간의
  // 날짜 / 시각을 그대로 표시함.
  //
  // Emulator timezone에 의해 UTC로 밀리는 것을 방지.
  // ==========================================================

  static DateTime _parseServerDateTime(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.length >= 19) {
      return DateTime.parse(text.substring(0, 19));
    }

    return DateTime.parse(text);
  }

  // ==========================================================
  // JSON → Model
  // ==========================================================

  factory StaffSchedule.fromJson(Map<String, dynamic> json) {
    return StaffSchedule(
      id: json['id'] as int,
      user: json['user'] as int,
      title: json['title']?.toString() ?? '',
      scheduleType: json['schedule_type']?.toString() ?? '',
      startsAt: _parseServerDateTime(json['starts_at']),
      endsAt: _parseServerDateTime(json['ends_at']),
      description: json['description']?.toString(),
      isAllDay: json['is_all_day'] as bool? ?? false,
      color: json['color']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }

  // ==========================================================
  // 일정 종류 한글 표시
  // ==========================================================

  String get scheduleTypeLabel {
    switch (scheduleType) {
      case 'CLINICAL':
        return '진료';

      case 'ON_CALL':
        return '당직';

      case 'OFF':
        return '휴무';

      default:
        return title;
    }
  }

  // ==========================================================
  // 활성 일정 여부
  // ==========================================================

  bool get isActive {
    return status == 'ACTIVE';
  }
}
