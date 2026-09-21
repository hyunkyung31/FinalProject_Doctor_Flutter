// ============================================================
// STEP 1. Attendance Type
// ============================================================

enum AttendanceType {
  annualLeave,
  halfDayAm,
  halfDayPm,
  hourlyLeave,
  sickLeave,
  officialLeave,
  businessTrip,
  education,
}

// ============================================================
// STEP 2. Attendance Type Extension
// Backend Enum ↔ Flutter 변환
// ============================================================

extension AttendanceTypeExtension on AttendanceType {
  String get apiValue {
    switch (this) {
      case AttendanceType.annualLeave:
        return 'ANNUAL_LEAVE';
      case AttendanceType.halfDayAm:
        return 'HALF_DAY_AM';
      case AttendanceType.halfDayPm:
        return 'HALF_DAY_PM';
      case AttendanceType.hourlyLeave:
        return 'HOURLY_LEAVE';
      case AttendanceType.sickLeave:
        return 'SICK_LEAVE';
      case AttendanceType.officialLeave:
        return 'OFFICIAL_LEAVE';
      case AttendanceType.businessTrip:
        return 'BUSINESS_TRIP';
      case AttendanceType.education:
        return 'EDUCATION';
    }
  }

  String get label {
    switch (this) {
      case AttendanceType.annualLeave:
        return '연차';
      case AttendanceType.halfDayAm:
        return '오전 반차';
      case AttendanceType.halfDayPm:
        return '오후 반차';
      case AttendanceType.hourlyLeave:
        return '시간차';
      case AttendanceType.sickLeave:
        return '병가';
      case AttendanceType.officialLeave:
        return '공가';
      case AttendanceType.businessTrip:
        return '출장';
      case AttendanceType.education:
        return '교육';
    }
  }

  static AttendanceType fromApiValue(String value) {
    switch (value) {
      case 'HALF_DAY_AM':
        return AttendanceType.halfDayAm;
      case 'HALF_DAY_PM':
        return AttendanceType.halfDayPm;
      case 'HOURLY_LEAVE':
        return AttendanceType.hourlyLeave;
      case 'SICK_LEAVE':
        return AttendanceType.sickLeave;
      case 'OFFICIAL_LEAVE':
        return AttendanceType.officialLeave;
      case 'BUSINESS_TRIP':
        return AttendanceType.businessTrip;
      case 'EDUCATION':
        return AttendanceType.education;
      case 'ANNUAL_LEAVE':
      default:
        return AttendanceType.annualLeave;
    }
  }
}

// ============================================================
// STEP 3. Attendance Request
// 실제 Backend Response Model
// ============================================================

class AttendanceRequest {
  final int id;

  final int requester;
  final String requesterName;

  final AttendanceType attendanceType;

  final DateTime startDate;
  final DateTime endDate;

  final String? startTime;
  final String? endTime;

  final bool isAllDay;
  final String? memo;

  final String status;
  final double leaveDays;

  final int? approvedSchedule;

  final int? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewComment;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRequest({
    required this.id,
    required this.requester,
    required this.requesterName,
    required this.attendanceType,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.memo,
    required this.status,
    required this.leaveDays,
    required this.approvedSchedule,
    required this.reviewedBy,
    required this.reviewedByName,
    required this.reviewedAt,
    required this.reviewComment,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // STEP 4. JSON → Model
  // ============================================================

  factory AttendanceRequest.fromJson(Map<String, dynamic> json) {
    return AttendanceRequest(
      id: _toInt(json['id']),
      requester: _toInt(json['requester']),
      requesterName: json['requester_name']?.toString() ?? '',
      attendanceType: AttendanceTypeExtension.fromApiValue(
        json['attendance_type']?.toString() ?? '',
      ),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isAllDay: json['is_all_day'] == true,
      memo: json['memo']?.toString(),
      status: json['status']?.toString() ?? '',
      leaveDays: _toDouble(json['leave_days']),
      approvedSchedule: _toNullableInt(json['approved_schedule']),
      reviewedBy: _toNullableInt(json['reviewed_by']),
      reviewedByName: json['reviewed_by_name']?.toString(),
      reviewedAt: _toNullableDateTime(json['reviewed_at']),
      reviewComment: json['review_comment']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  // ============================================================
  // STEP 5. UI Helpers
  // ============================================================

  bool get isPending => status == 'PENDING';

  bool get isApproved => status == 'APPROVED';

  bool get isRejected => status == 'REJECTED';

  bool get isCancelled => status == 'CANCELLED' || status == 'CANCELED';

  String get attendanceTypeLabel => attendanceType.label;

  // ============================================================
  // STEP 6. Parsing Helpers
  // ============================================================

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}

// ============================================================
// STEP 7. Leave Balance
// ============================================================

class LeaveBalance {
  final int year;

  final double totalDays;
  final double usedDays;
  final double remainingDays;

  final int pendingCount;

  const LeaveBalance({
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
    required this.pendingCount,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      year: _toInt(json['year']),
      totalDays: _toDouble(json['total_days']),
      usedDays: _toDouble(json['used_days']),
      remainingDays: _toDouble(json['remaining_days']),
      pendingCount: _toInt(json['pending_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
