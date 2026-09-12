import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'today_schedule_models.dart';

// ============================================================
// STEP 1. Today Schedule Item
// Timeline에서 일정 한 건을 표시하는 Widget
// ============================================================

class TodayScheduleItem extends StatelessWidget {
  final TodayScheduleData data;

  final bool selected;
  final bool first;
  final bool last;

  final VoidCallback onTap;

  const TodayScheduleItem({
    super.key,
    required this.data,
    required this.selected,
    required this.first,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // Timeline Indicator Color
    // ==========================================================

    final indicatorColor = data.current
        ? AppColors.danger
        : data.completed
        ? AppColors.success
        : AppColors.border;

    // ==========================================================
    // Timeline Line Color
    //
    // 완료 → 현재 구간까지는 Green
    // 이후 예정 구간은 Gray
    // ==========================================================

    final topLineColor = data.completed || data.current
        ? AppColors.success
        : AppColors.border;

    final bottomLineColor = data.completed
        ? AppColors.success
        : AppColors.border;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(AppRadius.small),

        child: Container(
          constraints: const BoxConstraints(minHeight: 56),

          decoration: BoxDecoration(
            // ====================================================
            // 선택된 일정
            // NOW와 선택 상태는 별도로 표현
            // ====================================================
            color: selected ? const Color(0xFFF8FAFC) : Colors.transparent,

            borderRadius: BorderRadius.circular(AppRadius.small),

            border: selected
                ? const Border(
                    left: BorderSide(color: AppColors.primaryBlue, width: 2),
                  )
                : null,
          ),

          padding: EdgeInsets.fromLTRB(selected ? 10 : 12, 7, 10, 7),

          child: Row(
            children: [
              // ==================================================
              // Time
              // ==================================================
              SizedBox(
                width: 46,

                child: Text(
                  data.time,

                  style: TextStyle(
                    color: data.current
                        ? AppColors.danger
                        : AppColors.textSecondary,

                    fontSize: 10.5,

                    fontWeight: data.current
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),

              // ==================================================
              // Timeline
              // ==================================================
              SizedBox(
                width: 18,
                height: 42,

                child: Stack(
                  alignment: Alignment.center,

                  children: [
                    // ==============================================
                    // 위쪽 연결선
                    // ==============================================
                    if (!first)
                      Positioned(
                        top: 0,

                        child: Container(
                          width: 1,
                          height: 17,

                          color: topLineColor,
                        ),
                      ),

                    // ==============================================
                    // 아래쪽 연결선
                    // ==============================================
                    if (!last)
                      Positioned(
                        bottom: 0,

                        child: Container(
                          width: 1,
                          height: 17,

                          color: bottomLineColor,
                        ),
                      ),

                    // ==============================================
                    // Timeline Dot
                    // ==============================================
                    Container(
                      width: data.current ? 9 : 7,
                      height: data.current ? 9 : 7,

                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,

                        border: data.current
                            ? Border.all(
                                color: AppColors.dangerBackground,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // ==================================================
              // Patient + Schedule
              // ==================================================
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      '${data.patientName} · ${data.age}',

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10.5,

                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      data.title,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // Status
              // ==================================================
              _ScheduleStatusTag(
                text: data.status,
                danger: data.current,
                success: data.completed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 2. Schedule Status Tag
// Today Schedule Item 내부 전용 상태 Tag
// ============================================================

class _ScheduleStatusTag extends StatelessWidget {
  final String text;

  final bool danger;
  final bool success;

  const _ScheduleStatusTag({
    required this.text,
    this.danger = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    if (danger) {
      background = AppColors.dangerBackground;
      foreground = AppColors.danger;
    } else if (success) {
      background = AppColors.successBackground;
      foreground = AppColors.success;
    } else {
      background = AppColors.surfaceSoft;
      foreground = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(AppRadius.round),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
