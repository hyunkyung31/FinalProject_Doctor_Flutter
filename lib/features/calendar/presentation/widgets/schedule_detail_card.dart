import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/staff_schedule.dart';

// ============================================================
// STEP 1. Schedule Detail Card
// 선택 날짜의 개별 일정 상세
// ============================================================

class ScheduleDetailCard extends StatelessWidget {
  final StaffSchedule schedule;
  final Color color;
  final String timeText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleDetailCard({
    super.key,
    required this.schedule,
    required this.color,
    required this.timeText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonal = schedule.scheduleType == 'PERSONAL';

    final title = isPersonal
        ? schedule.title
        : _officialScheduleTitle(schedule);

    final description = schedule.description?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // 일정 Accent Line
            // ==================================================
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(width: 12),

            // ==================================================
            // 일정 내용
            // ==================================================
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==============================================
                  // 제목 + 개인 일정 Menu
                  // ==============================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),

                      if (isPersonal) ...[
                        const SizedBox(width: 6),

                        _ScheduleMenu(onEdit: onEdit, onDelete: onDelete),
                      ],
                    ],
                  ),

                  // ==============================================
                  // 제목 ↔ 시간 간격
                  // ==============================================
                  const SizedBox(height: 7),

                  // ==============================================
                  // 시간
                  // ==============================================
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: isPersonal ? color : AppColors.textSecondary,
                    ),
                  ),

                  // ==============================================
                  // 개인 일정 Memo
                  // 메모 | 작성 내용
                  // ==============================================
                  if (isPersonal && description.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          width: 1,
                          height: 13,
                          margin: const EdgeInsets.only(top: 1),
                          color: AppColors.border,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2. 공식 일정 표시 이름
  // ============================================================

  String _officialScheduleTitle(StaffSchedule schedule) {
    switch (schedule.scheduleType) {
      case 'CLINICAL':
        return '진료';

      case 'ON_CALL':
        return '당직';

      case 'OFF':
        return '휴무';

      default:
        return schedule.title;
    }
  }
}

// ============================================================
// STEP 3. 개인 일정 Menu
// 수정 / 삭제
// ============================================================

class _ScheduleMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '일정 메뉴',
      padding: EdgeInsets.zero,

      constraints: const BoxConstraints(minWidth: 120),

      // ========================================================
      // Menu 버튼 높이를 작게 제한
      // 제목 Row 높이가 불필요하게 커지는 현상 방지
      // ========================================================
      child: const SizedBox(
        width: 28,
        height: 20,
        child: Center(
          child: Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),

      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;

          case 'delete':
            onDelete();
            break;
        }
      },

      itemBuilder: (context) {
        return const [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 17),

                SizedBox(width: 10),

                Text('수정'),
              ],
            ),
          ),

          PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: AppColors.danger,
                ),

                SizedBox(width: 10),

                Text('삭제', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
