// ============================================================
// STEP 1. Today Schedule Data
// 환자별 일정 정보를 표현하는 Data Model
// ============================================================

class TodayScheduleData {
  final String time;

  final String patientName;
  final String age;
  final String patientId;

  final String title;
  final String status;

  final List<String> tags;

  final bool completed;
  final bool current;

  const TodayScheduleData({
    required this.time,
    required this.patientName,
    required this.age,
    required this.patientId,
    required this.title,
    required this.status,
    this.tags = const [],
    this.completed = false,
    this.current = false,
  });
}

// ============================================================
// STEP 2. Weekly Date Data
// Dashboard Weekly Date Strip에서 사용하는 Data Model
// ============================================================

class WeekDayData {
  final String weekDay;
  final int day;

  final bool isToday;
  final bool isWeekend;

  const WeekDayData({
    required this.weekDay,
    required this.day,
    this.isToday = false,
    this.isWeekend = false,
  });
}
