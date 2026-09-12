import 'package:flutter/material.dart';

import '../dashboard_section_card.dart';

import 'schedule_detail.dart';
import 'today_schedule_item.dart';
import 'today_schedule_models.dart';
import 'weekly_date_strip.dart';

// ============================================================
// STEP 7. Today Schedule
// Today Flow + Next Appointment 통합
// ============================================================

class TodayScheduleCard extends StatefulWidget {
  const TodayScheduleCard({super.key});

  @override
  State<TodayScheduleCard> createState() => _TodayScheduleCardState();
}

class _TodayScheduleCardState extends State<TodayScheduleCard> {
  // ==========================================================
  // 주간 Date Strip Mock Data
  // 2026.09.07 ~ 2026.09.13
  // ==========================================================

  static const List<WeekDayData> _weekDays = [
    WeekDayData(weekDay: '월', day: 7),

    WeekDayData(weekDay: '화', day: 8),

    WeekDayData(weekDay: '수', day: 9, isToday: true),

    WeekDayData(weekDay: '목', day: 10),

    WeekDayData(weekDay: '금', day: 11),

    WeekDayData(weekDay: '토', day: 12, isWeekend: true),

    WeekDayData(weekDay: '일', day: 13, isWeekend: true),
  ];

  // 현재 선택 날짜
  int _selectedDayIndex = 2;
  int _selectedIndex = 1;

  // ==========================================================
  // 오늘 날짜 선택 시 기본 일정 결정
  // 1. 현재 일정
  // 2. 가장 가까운 예정 일정
  // 3. 없으면 첫 번째 일정
  // ==========================================================

  int _getDefaultScheduleIndex() {
    // 현재 진행 중인 일정 찾기
    final currentIndex = _items.indexWhere((item) => item.current);

    if (currentIndex >= 0) {
      return currentIndex;
    }

    // 아직 완료되지 않은 가장 가까운 일정 찾기
    final upcomingIndex = _items.indexWhere((item) => !item.completed);

    if (upcomingIndex >= 0) {
      return upcomingIndex;
    }

    // 모든 일정이 완료된 경우 첫 번째 일정
    return 0;
  }

  // ==========================================================
  // Mock Data
  // 추후 Today Schedule API로 교체
  // ==========================================================

  static const List<TodayScheduleData> _items = [
    TodayScheduleData(
      time: '09:00',
      patientName: '박OO',
      age: '78세',
      patientId: 'P-20260134',
      title: '외래 진료',
      status: '완료',
      tags: ['심부전', '고혈압'],
      completed: true,
    ),

    TodayScheduleData(
      time: '10:30',
      patientName: '김OO',
      age: '68세',
      patientId: 'P-20260428',
      title: 'CCTA 결과 상담',
      status: 'NOW',
      tags: ['고혈압 추적', 'CAC 증가'],
      current: true,
    ),

    TodayScheduleData(
      time: '13:30',
      patientName: '이OO',
      age: '65세',
      patientId: 'P-20260312',
      title: '영상의학과 협진',
      status: '예정',
      tags: ['CAC Score 상승'],
    ),

    TodayScheduleData(
      time: '15:00',
      patientName: '최OO',
      age: '71세',
      patientId: 'P-20260510',
      title: '외래 진료',
      status: '예정',
      tags: ['추적 관찰'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _items[_selectedIndex];

    final textScaler = MediaQuery.textScalerOf(context);

    final textScale = textScaler.scale(16) / 16;

    final isTodaySelected = _weekDays[_selectedDayIndex].isToday;

    return DashboardSectionCard(
      title: 'TODAY SCHEDULE',

      actionLabel: '캘린더',

      onAction: () {
        _showTodayScheduleMessage(context, '전체 캘린더 화면으로 이동');
      },

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // ======================================================
            // Weekly Date Strip
            // ======================================================
            WeeklyDateStrip(
              days: _weekDays,
              selectedIndex: _selectedDayIndex,

              onSelected: (index) {
                setState(() {
                  _selectedDayIndex = index;

                  // 오늘을 선택하면 현재/가장 가까운 일정 자동 선택
                  if (_weekDays[index].isToday) {
                    _selectedIndex = _getDefaultScheduleIndex();
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            // ======================================================
            // 선택한 날짜에 따른 일정 영역
            // ======================================================
            if (!isTodaySelected)
              EmptyDaySchedule(data: _weekDays[_selectedDayIndex])
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final useHorizontalLayout =
                      constraints.maxWidth >= 600 && textScale < 1.25;

                  // ==================================================
                  // 기본 / 115%
                  // 일정 목록 + 상세 좌우 배치
                  // ==================================================

                  if (useHorizontalLayout) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Expanded(flex: 5, child: _buildScheduleList()),

                        const SizedBox(width: 14),

                        Expanded(
                          flex: 4,
                          child: ScheduleDetail(data: selected),
                        ),
                      ],
                    );
                  }

                  // ==================================================
                  // 큰 글씨
                  // 일정 목록 + 상세 세로 배치
                  // ==================================================

                  return Column(
                    children: [
                      _buildScheduleList(),

                      const SizedBox(height: 12),

                      const Divider(height: 1),

                      const SizedBox(height: 12),

                      ScheduleDetail(data: selected),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Today Schedule List
  // ==========================================================

  Widget _buildScheduleList() {
    return Column(
      children: [
        for (int index = 0; index < _items.length; index++)
          TodayScheduleItem(
            data: _items[index],
            selected: index == _selectedIndex,
            first: index == 0,
            last: index == _items.length - 1,

            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
      ],
    );
  }
}

// ============================================================
// Temporary Today Schedule Message
// 추후 Calendar Routing 연결 시 제거 예정
// ============================================================

void _showTodayScheduleMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
}
