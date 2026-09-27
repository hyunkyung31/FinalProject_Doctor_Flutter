import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../appointments/presentation/appointment_ui_model.dart';
import '../../data/services/today_hub_service.dart';

// ============================================================
// STEP 1. Today Hub Card
// DashboardPage에서 공유받은 데이터만 사용
// 자체 API 호출 없음
// ============================================================

class TodayHubCard extends StatelessWidget {
  final TodayHubData data;

  const TodayHubCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          _Header(
            count: data.schedules.length + data.reservations.length,
            onTap: () {
              context.go('/calendar');
            },
          ),

          Divider(height: 1, color: context.appBorder),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 480) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 188, child: _MiniCalendar()),

                      const SizedBox(width: 10),

                      Expanded(child: _ScheduleSection(items: data.schedules)),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _ReservationSection(items: data.reservations),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    const _MiniCalendar(),

                    const SizedBox(height: 12),

                    _ScheduleSection(items: data.schedules),

                    const SizedBox(height: 12),

                    _ReservationSection(items: data.reservations),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _Header({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 7, 6),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 14,
              color: context.appBrand,
            ),
            const SizedBox(width: 7),
            Text(
              '오늘 일정',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.appBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    '일정',
                    style: TextStyle(
                      fontSize: 9,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: context.appTextSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Mini Calendar
// ============================================================

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar();

  @override
  Widget build(BuildContext context) {
    final today = dashboardNowKst();

    final first = DateTime(today.year, today.month, 1);

    final start = first.subtract(Duration(days: first.weekday % 7));

    // ============================================================
    // 실제 필요한 주까지만 표시
    // 5주짜리 달은 35칸, 6주짜리 달은 42칸
    // ============================================================

    final last = DateTime(today.year, today.month + 1, 0);

    final end = last.add(Duration(days: 6 - (last.weekday % 7)));

    final dayCount = end.difference(start).inDays + 1;

    final days = List.generate(
      dayCount,
      (index) => start.add(Duration(days: index)),
    );

    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return InkWell(
      onTap: () {
        context.go('/calendar');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        // 위쪽은 적당히 유지,
        // 아래쪽 불필요한 공간만 축소
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        decoration: BoxDecoration(
          color: context.appBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Calendar Header
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${today.year}년 ${today.month}월',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '오늘',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: context.appBrand,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Weekdays
            Row(
              children: [
                for (final weekday in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 3),

            // Days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 20,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];

                final isToday =
                    day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                final outside = day.month != today.month;

                return Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.navy : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday
                            ? Colors.white
                            : outside
                            ? context.appTextSecondary.withValues(alpha: 0.35)
                            : context.appTextPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<TodayHubScheduleItem> items;

  const _ScheduleSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _HubSection(
      title: '개인·업무 일정',
      count: items.length,
      dotColor: AppColors.primaryBlue,
      emptyText: '오늘 등록된 일정이 없습니다.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items.take(4))
            _HubRow(
              time: item.isAllDay ? '종일' : _formatTime(item.startsAt),
              title: item.title,
              subtitle: item.isAllDay
                  ? item.typeLabel
                  : '${_formatTime(item.startsAt)}–'
                        '${_formatTime(item.endsAt)} · '
                        '${item.typeLabel}',
              onTap: () {
                context.go('/calendar');
              },
            ),
        ],
      ),
    );
  }
}

class _ReservationSection extends StatelessWidget {
  final List<TodayHubReservationItem> items;

  const _ReservationSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _HubSection(
      title: '예약 환자',
      count: items.length,
      dotColor: AppColors.warning,
      emptyText: '오늘 예약 환자가 없습니다.',
      child: Column(
        children: [
          for (final item in items.take(4))
            _HubRow(
              time: _formatTime(item.reservedAt),
              title: item.applicantName,
              subtitle: item.status.label,
              statusColor: _statusColor(item.status),
              onTap: () {
                context.go('/appointments');
              },
            ),
        ],
      ),
    );
  }
}

class _HubSection extends StatelessWidget {
  final String title;
  final int count;
  final Color dotColor;
  final String emptyText;
  final Widget child;

  const _HubSection({
    required this.title,
    required this.count,
    required this.dotColor,
    required this.emptyText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (count == 0)
          Container(
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emptyText,
              style: TextStyle(fontSize: 8.8, color: context.appTextSecondary),
            ),
          )
        else
          child,
      ],
    );
  }
}

class _HubRow extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final Color? statusColor;
  final VoidCallback onTap;

  const _HubRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 35,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: statusColor ?? context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.requested:
      return AppColors.warning;
    case AppointmentStatus.accepted:
      return AppColors.success;
    case AppointmentStatus.canceled:
      return AppColors.danger;
  }
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
