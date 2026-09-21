// ============================================================
// STEP 1. On-Call Schedule
//
// GET /staff/admin/schedules/
// + GET /doctors/
// 응답을 결합한 당직 현황용 Model
// ============================================================

class OnCallSchedule {
  final int id;
  final int userId;

  final String title;

  final DateTime startsAt;
  final DateTime endsAt;

  final String doctorName;
  final int? departmentId;
  final String department;

  final String dutyType;
  final String status;

  final bool isMine;

  const OnCallSchedule({
    required this.id,
    required this.userId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.doctorName,
    required this.departmentId,
    required this.department,
    required this.dutyType,
    required this.status,
    required this.isMine,
  });

  // ============================================================
  // STEP 2. UI Helpers
  // ============================================================

  DateTime get date {
    final local = startsAt.toLocal();

    return DateTime(local.year, local.month, local.day);
  }

  String get startTime {
    return _formatTime(startsAt.toLocal());
  }

  String get endTime {
    return _formatTime(endsAt.toLocal());
  }

  bool get isActive {
    return status == 'ACTIVE';
  }

  // ============================================================
  // STEP 3. Formatting
  // ============================================================

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
