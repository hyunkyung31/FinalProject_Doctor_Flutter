import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'today_schedule_models.dart';

// ============================================================
// STEP 1. Weekly Date Strip
// 월요일 ~ 일요일 날짜 선택 영역
// ============================================================

class WeeklyDateStrip extends StatelessWidget {
  final List<WeekDayData> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const WeeklyDateStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),

      child: Row(
        children: [
          for (int index = 0; index < days.length; index++)
            Expanded(
              child: _WeeklyDateItem(
                data: days[index],
                selected: index == selectedIndex,

                onTap: () {
                  onSelected(index);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Weekly Date Item
// Weekly Date Strip 내부에서만 사용하는 Private Widget
// ============================================================

class _WeeklyDateItem extends StatelessWidget {
  final WeekDayData data;
  final bool selected;
  final VoidCallback onTap;

  const _WeeklyDateItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(AppRadius.medium),

        child: Container(
          constraints: const BoxConstraints(minHeight: 42),

          margin: const EdgeInsets.symmetric(horizontal: 2),

          padding: const EdgeInsets.symmetric(vertical: 3),

          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,

            borderRadius: BorderRadius.circular(AppRadius.medium),

            border: selected ? Border.all(color: AppColors.border) : null,
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // ==================================================
              // 요일
              // ==================================================
              Text(
                data.weekDay,

                style: TextStyle(
                  color: data.isWeekend
                      ? AppColors.textSecondary
                      : selected
                      ? AppColors.navy
                      : AppColors.textSecondary,

                  fontSize: 9,

                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              // ==================================================
              // 날짜
              // ==================================================
              Text(
                '${data.day}',

                style: TextStyle(
                  color: selected ? AppColors.navy : AppColors.textPrimary,

                  fontSize: 12,

                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              // ==================================================
              // 오늘 표시
              // ==================================================
              SizedBox(
                height: 5,

                child: data.isToday
                    ? Container(
                        width: 5,
                        height: 5,

                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Empty Day Schedule
// 현재 Mock 일정이 없는 날짜의 Empty State
// ============================================================

class EmptyDaySchedule extends StatelessWidget {
  final WeekDayData data;

  const EmptyDaySchedule({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),

        borderRadius: BorderRadius.circular(AppRadius.medium),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.textDisabled,
            size: 26,
          ),

          const SizedBox(height: 8),

          Text(
            '${data.weekDay}요일 ${data.day}일',

            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            '등록된 일정이 없습니다.',

            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
