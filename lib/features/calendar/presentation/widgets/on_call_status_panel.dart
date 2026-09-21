import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/on_call_schedule.dart';
import '../../data/services/on_call_status_service.dart';

// ============================================================
// STEP 2. 화면 모드
// ============================================================

enum _OnCallViewMode { calendar, list }

// ============================================================
// STEP 3. 당직 현황 Panel
// ============================================================

class OnCallStatusPanel extends StatefulWidget {
  const OnCallStatusPanel({super.key});

  @override
  State<OnCallStatusPanel> createState() => _OnCallStatusPanelState();
}

class _OnCallStatusPanelState extends State<OnCallStatusPanel>
    with WidgetsBindingObserver {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  String _selectedDepartment = '전체';
  _OnCallViewMode _viewMode = _OnCallViewMode.calendar;

  final List<OnCallSchedule> _items = [];

  List<String> _departments = const ['전체'];

  bool _isLoading = true;
  String? _loadError;
  bool _didInitialLoad = false;
  late DateTime _lastActiveDate;

  // ============================================================
  // 한국 표준시 기준 현재 시각
  // ============================================================

  DateTime _nowKst() {
    return DateTime.now().toUtc().add(const Duration(hours: 9));
  }

  @override
  void initState() {
    super.initState();

    final now = _nowKst();

    _focusedMonth = DateTime(now.year, now.month, 1);

    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  // ============================================================
  // 날짜 변경 감지
  //
  // 태블릿 앱을 하루 이상 켜둔 경우
  // 앱 복귀 시 선택 날짜를 오늘로 자동 보정.
  // 단, 사용자가 과거 날짜를 직접 보고 있었다면 유지.
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final now = _nowKst();

    final today = DateTime(now.year, now.month, now.day);

    final dayChanged = !_isSameDate(_lastActiveDate, today);

    final wasFollowingToday = _isSameDate(_selectedDate, _lastActiveDate);

    _lastActiveDate = today;

    if (!dayChanged || !wasFollowingToday) {
      return;
    }

    setState(() {
      _focusedMonth = DateTime(today.year, today.month, 1);

      _selectedDate = today;
    });

    debugPrint(
      '[ON_CALL DATE] 날짜 변경 감지 → '
      '오늘 ${today.year}.${today.month}.${today.day} 선택',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialLoad) {
      return;
    }

    _didInitialLoad = true;

    unawaited(_loadOnCallSchedules());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // STEP 4. 실제 당직 일정 조회
  // ============================================================

  Future<void> _loadOnCallSchedules({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final apiClient = context.read<ApiClient>();
      final auth = context.read<AuthProvider>();

      final service = OnCallStatusService(apiClient: apiClient);

      final items = await service.fetchOnCallSchedules(
        currentUserId: auth.currentUser?.id,
      );

      if (!mounted) {
        return;
      }

      final departmentSet =
          items
              .map((item) => item.department)
              .where((value) => value.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final departments = ['전체', ...departmentSet];

      setState(() {
        _items
          ..clear()
          ..addAll(items);

        _departments = departments;

        if (!_departments.contains(_selectedDepartment)) {
          _selectedDepartment = '전체';
        }

        _isLoading = false;
        _loadError = null;
      });

      debugPrint(
        '[ON_CALL] 실제 당직 ${items.length}건 조회 완료 / '
        '진료과 ${departmentSet.length}개',
      );
    } catch (error) {
      debugPrint('[ON_CALL] 당직 현황 조회 실패: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '당직 현황을 불러오지 못했습니다.';
      });
    }
  }

  // ============================================================
  // STEP 5. Filtered Data
  // ============================================================

  List<OnCallSchedule> get _filteredItems {
    final items = _items.where((item) {
      return _selectedDepartment == '전체' ||
          item.department == _selectedDepartment;
    }).toList();

    items.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.startTime.compareTo(b.startTime);
    });

    return items;
  }

  List<OnCallSchedule> get _selectedDateItems {
    return _filteredItems.where((item) {
      return _isSameDate(item.date, _selectedDate);
    }).toList();
  }

  List<OnCallSchedule> get _monthItems {
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

    return _filteredItems.where((item) {
      final itemDate = _dateOnly(item.date);

      return !itemDate.isBefore(start) && itemDate.isBefore(end);
    }).toList();
  }

  // ============================================================
  // STEP 6. Calendar Dates
  // 항상 6주(42칸)로 고정하여 월 변경 시 레이아웃 흔들림 방지
  // ============================================================

  List<DateTime> get _calendarDates {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    final gridStart = firstDay.subtract(
      Duration(days: firstDay.weekday - DateTime.monday),
    );

    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }

  // ============================================================
  // STEP 7. Main UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(height: 10),

            Text(
              _loadError!,
              style: TextStyle(fontSize: 11, color: context.appTextSecondary),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                _loadOnCallSchedules();
              },
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildToolbar(),

        const SizedBox(height: 10),

        Expanded(
          child: _viewMode == _OnCallViewMode.calendar
              ? _buildCalendarMode()
              : _buildListMode(),
        ),
      ],
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
            color: context.appSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              _DateNavigationButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _movePreviousMonth,
              ),

              Container(
                width: 142,
                alignment: Alignment.center,
                child: Text(
                  '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              _DateNavigationButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _moveNextMonth,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _goToday,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.appBorder),
            ),
            icon: const Icon(Icons.today_outlined, size: 15),
            label: const Text('오늘', style: TextStyle(fontSize: 10.5)),
          ),
        ),

        const Spacer(),

        Row(
          children: [
            Icon(
              Icons.nights_stay_outlined,
              size: 14,
              color: context.appTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              '의료진 당직 현황',
              style: TextStyle(fontSize: 10, color: context.appTextSecondary),
            ),
          ],
        ),

        const SizedBox(width: 10),

        // ======================================================
        // 진료과 Dropdown
        // ======================================================
        Container(
          width: 180,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.appBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
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

        const SizedBox(width: 8),

        _ViewModeToggle(
          selectedMode: _viewMode,
          onChanged: (mode) {
            setState(() {
              _viewMode = mode;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // STEP 9. 월간 달력 Mode
  //
  // 좌측: 월간 달력
  // 우측: 선택 날짜 당직 상세
  // ============================================================

  Widget _buildCalendarMode() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 7, child: _buildMonthlyCalendar()),

        const SizedBox(width: 12),

        Expanded(flex: 3, child: _buildSelectedDayDetail()),
      ],
    );
  }

  // ============================================================
  // STEP 10. 월간 Calendar
  // ============================================================

  Widget _buildMonthlyCalendar() {
    final dates = _calendarDates;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ======================================================
          // Weekday Header
          // ======================================================
          Container(
            height: 36,
            color: context.appSurfaceSoft,
            child: Row(
              children: [
                for (int index = 0; index < 7; index++)
                  Expanded(
                    child: Center(
                      child: Text(
                        _weekdayLabelFromIndex(index),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: index == 6
                              ? AppColors.danger
                              : index == 5
                              ? AppColors.primaryBlue
                              : context.appTextSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                for (int week = 0; week < 6; week++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int day = 0; day < 7; day++)
                          Expanded(
                            child: _CalendarDayCell(
                              date: dates[week * 7 + day],
                              items: _itemsForDate(dates[week * 7 + day]),
                              isFocusedMonth:
                                  dates[week * 7 + day].month ==
                                      _focusedMonth.month &&
                                  dates[week * 7 + day].year ==
                                      _focusedMonth.year,
                              isSelected: _isSameDate(
                                dates[week * 7 + day],
                                _selectedDate,
                              ),
                              isToday: _isSameDate(
                                dates[week * 7 + day],
                                _nowKst(),
                              ),
                              onTap: () {
                                _selectCalendarDate(dates[week * 7 + day]);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 11. 선택 날짜 상세
  // ============================================================

  Widget _buildSelectedDayDetail() {
    final items = _selectedDateItems;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.nightlight_outlined,
                  size: 17,
                  color: context.appBrand,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatSelectedDayTitle(_selectedDate),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _selectedDepartment == '전체'
                          ? '전체 진료과'
                          : _selectedDepartment,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appSurfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '총 ${items.length}명',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: context.appBrand,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: items.isEmpty
                ? const _EmptyDayState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _OnCallDoctorCard(item: items[index]);
                    },
                  ),
          ),

          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: context.appSurfaceSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.secondaryBlue,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '달력에서는 의료진을 간략히 표시하고, '
                      '선택한 날짜의 상세 정보는 이 영역에서 확인합니다.',
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.45,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP 12. 목록 Mode
  // ============================================================

  Widget _buildListMode() {
    final items = _monthItems;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
            child: Row(
              children: [
                Text(
                  '${_focusedMonth.year}년 '
                  '${_focusedMonth.month}월 당직',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '${items.length}건',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.appTextSecondary,
                  ),
                ),

                const Spacer(),

                Text(
                  _selectedDepartment == '전체' ? '전체 진료과' : _selectedDepartment,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: context.appSurfaceSoft,
            child: Row(
              children: [
                Expanded(
                  flex: 16,
                  child: Text('날짜', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 19,
                  child: Text('의료진', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 27,
                  child: Text('진료과', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 18,
                  child: Text('당직 구분', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 20,
                  child: Text('시간', style: _tableHeaderStyle(context)),
                ),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? const _EmptyMonthState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: context.appBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _MonthScheduleRow(
                        item: item,
                        selected: _isSameDate(item.date, _selectedDate),
                        onTap: () {
                          setState(() {
                            _selectedDate = item.date;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 13. Actions
  // ============================================================

  void _movePreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);

      _selectedDate = _focusedMonth;
    });
  }

  void _moveNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

      _selectedDate = _focusedMonth;
    });
  }

  void _goToday() {
    final now = _nowKst();

    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);

      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _selectCalendarDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);

      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  List<OnCallSchedule> _itemsForDate(DateTime date) {
    return _filteredItems.where((item) {
      return _isSameDate(item.date, date);
    }).toList();
  }
}

// ============================================================
// STEP 14. 월간 Calendar Day Cell
// ============================================================

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<OnCallSchedule> items;

  final bool isFocusedMonth;
  final bool isSelected;
  final bool isToday;

  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.items,
    required this.isFocusedMonth,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSunday = date.weekday == DateTime.sunday;

    final isSaturday = date.weekday == DateTime.saturday;

    Color dateColor = context.appTextPrimary;

    if (!isFocusedMonth) {
      dateColor = context.appTextDisabled;
    } else if (isSunday) {
      dateColor = AppColors.danger;
    } else if (isSaturday) {
      dateColor = AppColors.primaryBlue;
    }

    return Material(
      color: isSelected ? context.appSurfaceSoft : context.appSurface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: context.appBorder),
              bottom: BorderSide(color: context.appBorder),
            ),
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.06)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),

                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: dateColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              if (items.isNotEmpty)
                for (final item in items.take(2)) ...[
                  _CalendarDutyLine(item: item),
                  const SizedBox(height: 3),
                ],

              if (items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '+${items.length - 2}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
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
// STEP 15. 달력 내 당직 한 줄
// ============================================================

class _CalendarDutyLine extends StatelessWidget {
  final OnCallSchedule item;

  const _CalendarDutyLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final dutyColor = item.dutyType.contains('주말')
        ? AppColors.warning
        : AppColors.primaryBlue;

    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: dutyColor, shape: BoxShape.circle),
        ),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            '${_shortDoctorName(item.doctorName)} '
            '${_shortDutyType(item.dutyType)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: item.isMine ? FontWeight.w700 : FontWeight.w500,
              color: item.isMine ? AppColors.success : context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 16. 선택 날짜 의료진 Card
// ============================================================

class _OnCallDoctorCard extends StatelessWidget {
  final OnCallSchedule item;

  const _OnCallDoctorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: item.isMine ? context.appSurfaceSoft : context.appBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isMine
              ? AppColors.primaryBlue.withValues(alpha: 0.35)
              : context.appBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appSurface,
              shape: BoxShape.circle,
              border: Border.all(color: context.appBorder),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 17,
              color: context.appBrand,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),

                    if (item.isMine) ...[
                      const SizedBox(width: 6),
                      const _MyOnCallBadge(),
                    ],
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  item.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: context.appTextSecondary,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    _DutyTypeBadge(label: item.dutyType),

                    const Spacer(),

                    Text(
                      '${item.startTime} ~ ${item.endTime}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 17. 월간 목록 Row
// ============================================================

class _MonthScheduleRow extends StatelessWidget {
  final OnCallSchedule item;

  final bool selected;
  final VoidCallback onTap;

  const _MonthScheduleRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color rowColor = context.appSurface;

    if (item.isMine) {
      rowColor = context.appSurfaceSoft;
    } else if (selected) {
      rowColor = context.appBackground;
    }

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  flex: 16,
                  child: Text(
                    _formatListDate(item.date),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? AppColors.navy : context.appTextPrimary,
                    ),
                  ),
                ),

                Expanded(
                  flex: 19,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.doctorName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.appTextPrimary,
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

                Expanded(
                  flex: 27,
                  child: Text(
                    item.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),

                Expanded(
                  flex: 18,
                  child: Text(
                    item.dutyType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                Expanded(
                  flex: 20,
                  child: Text(
                    '${item.startTime} ~ ${item.endTime}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 18. 월간 / 목록 Toggle
// ============================================================

class _ViewModeToggle extends StatelessWidget {
  final _OnCallViewMode selectedMode;
  final ValueChanged<_OnCallViewMode> onChanged;

  const _ViewModeToggle({required this.selectedMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            label: '월간',
            icon: Icons.calendar_month_outlined,
            selected: selectedMode == _OnCallViewMode.calendar,
            onTap: () {
              onChanged(_OnCallViewMode.calendar);
            },
          ),
          _ViewModeButton(
            label: '목록',
            icon: Icons.view_list_outlined,
            selected: selectedMode == _OnCallViewMode.list,
            onTap: () {
              onChanged(_OnCallViewMode.list);
            },
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : context.appTextSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.appTextSecondary,
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
// STEP 19. 당직 구분 Badge
// ============================================================

class _DutyTypeBadge extends StatelessWidget {
  final String label;

  const _DutyTypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isWeekend = label.contains('주말');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isWeekend
            ? AppColors.warningBackground
            : AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: isWeekend ? AppColors.warning : AppColors.primaryBlue,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 20. 내 당직 Badge
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
// STEP 21. 날짜 Navigation Button
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
        icon: Icon(icon, size: 18, color: context.appBrand),
      ),
    );
  }
}

// ============================================================
// STEP 22. Empty States
// ============================================================

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.nights_stay_outlined,
              size: 28,
              color: AppColors.secondaryBlue,
            ),

            const SizedBox(height: 8),

            Text(
              '선택한 날짜에 당직 일정이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '다른 날짜 또는 진료과를 선택해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: context.appTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMonthState extends StatelessWidget {
  const _EmptyMonthState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 30,
            color: AppColors.secondaryBlue,
          ),

          const SizedBox(height: 8),

          Text(
            '선택한 월의 당직 일정이 없습니다.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '다른 월 또는 진료과를 선택해 보세요.',
            style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 23. Table Style
// ============================================================

TextStyle _tableHeaderStyle(BuildContext context) {
  return TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: context.appTextSecondary,
  );
}

// ============================================================
// STEP 24. Date Helpers
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

String _weekdayLabelFromIndex(int index) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];

  return labels[index];
}

String _formatSelectedDayTitle(DateTime date) {
  return '${date.month}월 ${date.day}일 '
      '${_weekdayLabel(date)}요일 당직 의료진';
}

String _formatListDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day (${_weekdayLabel(date)})';
}

String _shortDoctorName(String value) {
  return value.replaceAll(' 의사', '').trim();
}

String _shortDutyType(String value) {
  if (value.contains('야간')) {
    return '야간';
  }

  if (value.contains('주말')) {
    return '주말';
  }

  return value;
}
