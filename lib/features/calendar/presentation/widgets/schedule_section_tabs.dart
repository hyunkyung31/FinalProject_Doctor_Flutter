import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Schedule Section
// 일정 페이지 상단 Tab 구분
// ============================================================

enum ScheduleSection { mySchedule, leaveRequest, onCallStatus }

// ============================================================
// STEP 2. Schedule Section Tabs
// 선택된 Tab의 굵은 Underline만 표시
// ============================================================

class ScheduleSectionTabs extends StatelessWidget {
  final ScheduleSection selectedSection;
  final ValueChanged<ScheduleSection> onChanged;

  const ScheduleSectionTabs({
    super.key,
    required this.selectedSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScheduleTabButton(
          label: '내 스케줄',
          isSelected: selectedSection == ScheduleSection.mySchedule,
          onTap: () {
            onChanged(ScheduleSection.mySchedule);
          },
        ),

        _ScheduleTabButton(
          label: '휴무 신청',
          isSelected: selectedSection == ScheduleSection.leaveRequest,
          onTap: () {
            onChanged(ScheduleSection.leaveRequest);
          },
        ),

        _ScheduleTabButton(
          label: '당직 현황',
          isSelected: selectedSection == ScheduleSection.onCallStatus,
          onTap: () {
            onChanged(ScheduleSection.onCallStatus);
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 3. Tab Button
// ============================================================

class _ScheduleTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.navy : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.navy : AppColors.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
