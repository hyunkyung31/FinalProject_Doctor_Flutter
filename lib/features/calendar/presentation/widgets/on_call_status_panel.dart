import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 당직 현황 UI Preview Model
//
// 실제 당직 API Schema 확인 전까지 UI DEMO로 사용.
//
// 추후 Backend 연결 시 예시:
// - doctor
// - department
// - starts_at
// - ends_at
// - schedule_type = ON_CALL
// ============================================================

class _OnCallPreview {
  final int id;
  final DateTime date;

  final String doctorName;
  final String department;

  final String startTime;
  final String endTime;

  final String dutyType;

  final bool isMine;

  const _OnCallPreview({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.dutyType,
    this.isMine = false,
  });
}

// ============================================================
// STEP 2. 당직 현황 Panel
// ============================================================

class OnCallStatusPanel extends StatefulWidget {
  const OnCallStatusPanel({super.key});

  @override
  State<OnCallStatusPanel> createState() => _OnCallStatusPanelState();
}

class _OnCallStatusPanelState extends State<OnCallStatusPanel> {
  DateTime _selectedDate = DateTime(2026, 9, 14);

  String _selectedDepartment = '전체';

  static const List<String> _departments = ['전체', '순환기내과', '심장혈관흉부외과'];

  // ============================================================
  // STEP 3. UI DEMO Data
  // ============================================================

  static final List<_OnCallPreview> _previewItems = [
    _OnCallPreview(
      id: 1,
      date: DateTime(2026, 9, 14),
      doctorName: '박OO 의사',
      department: '순환기내과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 2,
      date: DateTime(2026, 9, 14),
      doctorName: '김OO 의사',
      department: '심장혈관흉부외과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
      isMine: true,
    ),
    _OnCallPreview(
      id: 3,
      date: DateTime(2026, 9, 15),
      doctorName: '최OO 의사',
      department: '순환기내과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 4,
      date: DateTime(2026, 9, 15),
      doctorName: '정OO 의사',
      department: '심장혈관흉부외과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 5,
      date: DateTime(2026, 9, 16),
      doctorName: '이OO 의사',
      department: '순환기내과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 6,
      date: DateTime(2026, 9, 17),
      doctorName: '한OO 의사',
      department: '순환기내과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 7,
      date: DateTime(2026, 9, 18),
      doctorName: '박OO 의사',
      department: '심장혈관흉부외과',
      startTime: '18:00',
      endTime: '08:00',
      dutyType: '야간 당직',
    ),
    _OnCallPreview(
      id: 8,
      date: DateTime(2026, 9, 19),
      doctorName: '김OO 의사',
      department: '순환기내과',
      startTime: '09:00',
      endTime: '09:00',
      dutyType: '주말 당직',
      isMine: true,
    ),
    _OnCallPreview(
      id: 9,
      date: DateTime(2026, 9, 20),
      doctorName: '최OO 의사',
      department: '순환기내과',
      startTime: '09:00',
      endTime: '09:00',
      dutyType: '주말 당직',
    ),
  ];

  // ============================================================
  // STEP 4. 선택 날짜 Data
  // ============================================================

  List<_OnCallPreview> get _selectedDateItems {
    return _previewItems.where((item) {
      final sameDate = _isSameDate(item.date, _selectedDate);

      final sameDepartment =
          _selectedDepartment == '전체' || item.department == _selectedDepartment;

      return sameDate && sameDepartment;
    }).toList();
  }

  // ============================================================
  // STEP 5. 현재 주 시작일 / 날짜
  // ============================================================

  DateTime get _weekStart {
    return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  List<DateTime> get _weekDates {
    return List.generate(7, (index) {
      return _weekStart.add(Duration(days: index));
    });
  }

  // ============================================================
  // STEP 6. 이번 주 Data
  // ============================================================

  List<_OnCallPreview> get _weekItems {
    final start = _dateOnly(_weekStart);

    final end = start.add(const Duration(days: 7));

    final items = _previewItems.where((item) {
      final itemDate = _dateOnly(item.date);

      final inWeek = !itemDate.isBefore(start) && itemDate.isBefore(end);

      final sameDepartment =
          _selectedDepartment == '전체' || item.department == _selectedDepartment;

      return inWeek && sameDepartment;
    }).toList();

    items.sort((a, b) => a.date.compareTo(b.date));

    return items;
  }

  // ============================================================
  // STEP 7. Main UI
  //
  // 좌우 분할 대신:
  //
  // Toolbar
  // Week Selector
  // 선택일 당직 가로 카드
  // 이번 주 당직 전체 폭 Table
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(),

          const SizedBox(height: 10),

          _buildWeekSelector(),

          const SizedBox(height: 12),

          _buildSelectedDayPanel(),

          const SizedBox(height: 12),

          _buildWeekSchedulePanel(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 8. Toolbar
  // ============================================================

  Widget _buildToolbar() {
    return Row(
      children: [
        // ======================================================
        // 월 이동
        // ======================================================
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _DateNavigationButton(
                icon: Icons.chevron_left_rounded,
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
              ),

              Container(
                width: 142,
                alignment: Alignment.center,
                child: Text(
                  '${_selectedDate.year}년 ${_selectedDate.month}월',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              _DateNavigationButton(
                icon: Icons.chevron_right_rounded,
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ======================================================
        // 오늘
        // ======================================================
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(2026, 9, 14);
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.today_outlined, size: 15),
            label: const Text('오늘', style: TextStyle(fontSize: 10.5)),
          ),
        ),

        const Spacer(),

        // ======================================================
        // 안내
        // ======================================================
        const Row(
          children: [
            Icon(
              Icons.nights_stay_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),

            SizedBox(width: 5),

            Text(
              '의료진 당직 현황',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // ======================================================
        // 진료과 Filter
        // ======================================================
        Container(
          width: 180,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 9. Week Selector
  // ============================================================

  Widget _buildWeekSelector() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int index = 0; index < _weekDates.length; index++) ...[
            Expanded(
              child: _WeekDateButton(
                date: _weekDates[index],
                selected: _isSameDate(_weekDates[index], _selectedDate),
                onTap: () {
                  setState(() {
                    _selectedDate = _weekDates[index];
                  });
                },
              ),
            ),

            if (index != _weekDates.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 10. 선택일 당직
  //
  // 기존 좌측 세로 Panel 대신
  // 전체 폭 + 가로 Card 구조
  // ============================================================

  Widget _buildSelectedDayPanel() {
    final items = _selectedDateItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // Header
          // ======================================================
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.nightlight_outlined,
                  size: 17,
                  color: AppColors.navy,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatSelectedDayTitle(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${items.length}명',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _selectedDepartment == '전체'
                          ? '전체 진료과 당직 의료진'
                          : '$_selectedDepartment 당직 의료진',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ======================================================
          // 당직 Card
          // ======================================================
          if (items.isEmpty)
            const SizedBox(height: 88, child: _EmptyDayState())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = (constraints.maxWidth - 10) / 2;

                final cardWidth = halfWidth > 520 ? 520.0 : halfWidth;

                return Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: cardWidth,
                        child: _OnCallDoctorCard(item: item),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 11. 이번 주 당직 Table
  // ============================================================

  Widget _buildWeekSchedulePanel() {
    final items = _weekItems;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
            child: Row(
              children: [
                const Text(
                  '이번 주 당직',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '${items.length}건',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Spacer(),

                Text(
                  '${_formatShortDate(_weekStart)} ~ '
                  '${_formatShortDate(_weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Table Header
          // ======================================================
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.surfaceSoft,
            child: const Row(
              children: [
                Expanded(flex: 16, child: Text('날짜', style: _tableHeaderStyle)),

                Expanded(
                  flex: 19,
                  child: Text('의료진', style: _tableHeaderStyle),
                ),

                Expanded(
                  flex: 27,
                  child: Text('진료과', style: _tableHeaderStyle),
                ),

                Expanded(
                  flex: 18,
                  child: Text('당직 구분', style: _tableHeaderStyle),
                ),

                Expanded(flex: 20, child: Text('시간', style: _tableHeaderStyle)),
              ],
            ),
          ),

          if (items.isEmpty)
            const SizedBox(height: 130, child: _EmptyWeekState())
          else
            for (int index = 0; index < items.length; index++) ...[
              _WeekScheduleRow(
                item: items[index],
                selected: _isSameDate(items[index].date, _selectedDate),
                onTap: () {
                  setState(() {
                    _selectedDate = items[index].date;
                  });
                },
              ),

              if (index != items.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }
}

// ============================================================
// STEP 12. Week Date Button
// ============================================================

class _WeekDateButton extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _WeekDateButton({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSunday = date.weekday == DateTime.sunday;

    final isSaturday = date.weekday == DateTime.saturday;

    Color dayColor = AppColors.textSecondary;

    if (isSunday) {
      dayColor = AppColors.danger;
    } else if (isSaturday) {
      dayColor = AppColors.primaryBlue;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekdayLabel(date),
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : dayColor,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 13. 선택일 당직 Card
// ============================================================

class _OnCallDoctorCard extends StatelessWidget {
  final _OnCallPreview item;

  const _OnCallDoctorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: item.isMine ? AppColors.surfaceSoft : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isMine
              ? AppColors.primaryBlue.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // ======================================================
          // Avatar
          // ======================================================
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(width: 10),

          // ======================================================
          // 의료진
          // ======================================================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (item.isMine) ...[
                      const SizedBox(width: 6),
                      const _MyOnCallBadge(),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  item.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // 당직 정보
          // ======================================================
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.dutyType,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '${item.startTime} ~ ${item.endTime}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 14. 주간 Table Row
// ============================================================

class _WeekScheduleRow extends StatelessWidget {
  final _OnCallPreview item;

  final bool selected;
  final VoidCallback onTap;

  const _WeekScheduleRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color rowColor = AppColors.surface;

    if (item.isMine) {
      rowColor = AppColors.surfaceSoft;
    } else if (selected) {
      rowColor = AppColors.background;
    }

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              // ==================================================
              // 날짜
              // ==================================================
              Expanded(
                flex: 16,
                child: Text(
                  _formatWeekTableDate(item.date),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.navy : AppColors.textPrimary,
                  ),
                ),
              ),

              // ==================================================
              // 의료진
              // ==================================================
              Expanded(
                flex: 19,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.doctorName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (item.isMine) ...[
                      const SizedBox(width: 6),
                      const _MyOnCallBadge(),
                    ],
                  ],
                ),
              ),

              // ==================================================
              // 진료과
              // ==================================================
              Expanded(
                flex: 27,
                child: Text(
                  item.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // ==================================================
              // 당직 구분
              // ==================================================
              Expanded(
                flex: 18,
                child: Text(
                  item.dutyType,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // ==================================================
              // 시간
              // ==================================================
              Expanded(
                flex: 20,
                child: Text(
                  '${item.startTime} ~ ${item.endTime}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 15. Date Navigation Button
// ============================================================

class _DateNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _DateNavigationButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: AppColors.navy),
      ),
    );
  }
}

// ============================================================
// STEP 16. 내 당직 Badge
// ============================================================

class _MyOnCallBadge extends StatelessWidget {
  const _MyOnCallBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '내 당직',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 17. Empty State
// ============================================================

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nights_stay_outlined,
            size: 20,
            color: AppColors.secondaryBlue,
          ),

          SizedBox(width: 8),

          Text(
            '선택한 날짜에 등록된 당직 의료진이 없습니다.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyWeekState extends StatelessWidget {
  const _EmptyWeekState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 30,
            color: AppColors.secondaryBlue,
          ),

          SizedBox(height: 8),

          Text(
            '이번 주 당직 일정이 없습니다.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 4),

          Text(
            '다른 주 또는 진료과를 선택해 보세요.',
            style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 18. Table Style
// ============================================================

const TextStyle _tableHeaderStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

// ============================================================
// STEP 19. Date Helpers
// ============================================================

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _weekdayLabel(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return '월';

    case DateTime.tuesday:
      return '화';

    case DateTime.wednesday:
      return '수';

    case DateTime.thursday:
      return '목';

    case DateTime.friday:
      return '금';

    case DateTime.saturday:
      return '토';

    case DateTime.sunday:
      return '일';

    default:
      return '';
  }
}

String _formatSelectedDayTitle(DateTime date) {
  return '${date.month}월 ${date.day}일 '
      '${_weekdayLabel(date)}요일 당직 의료진';
}

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}

String _formatWeekTableDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day (${_weekdayLabel(date)})';
}
