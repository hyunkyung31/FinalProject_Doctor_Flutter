import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../../core/auth/access_control.dart';
import '../../../../../core/auth/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';

import 'today_schedule_models.dart';

// ============================================================
// STEP 1. Schedule Detail
// 선택된 일정의 환자/진료 정보를 표시하는 Focus Panel
// ============================================================

class ScheduleDetail extends StatelessWidget {
  final TodayScheduleData data;

  const ScheduleDetail({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final canOpenPatient = auth.hasPermission(AppPermission.patientView);

    // ==========================================================
    // 현재 일정 상태
    // ==========================================================

    final statusText = data.current
        ? 'NOW'
        : data.completed
        ? '완료'
        : '예정';

    final statusColor = data.current
        ? AppColors.danger
        : data.completed
        ? AppColors.success
        : context.appPrimary;

    final statusBackground = data.current
        ? context.appDangerBackground
        : data.completed
        ? context.appSuccessBackground
        : context.appSurfaceSoft;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),

      decoration: BoxDecoration(
        color: context.appSurface,

        borderRadius: BorderRadius.circular(AppRadius.large),

        border: Border.all(color: context.appBorder),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisSize: MainAxisSize.min,

        children: [
          // ====================================================
          // Status + Time
          // ====================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

            decoration: BoxDecoration(
              color: statusBackground,

              borderRadius: BorderRadius.circular(AppRadius.round),
            ),

            child: Text(
              '$statusText · ${data.time}',

              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ====================================================
          // Patient
          // ====================================================
          Text(
            '${data.patientName} · ${data.age}',

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            data.patientId,

            style: TextStyle(
              color: context.appTextSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 9),

          // ====================================================
          // Schedule
          // ====================================================
          Text(
            '진료 일정',

            style: TextStyle(
              color: context.appTextSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            data.title,

            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),

          // ====================================================
          // Clinical Tags
          // ====================================================
          if (data.tags.isNotEmpty) ...[
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,

              children: [
                for (final tag in data.tags)
                  _ScheduleDetailTag(
                    text: tag,

                    // 현재 Mock 기준 CAC 관련 태그 강조
                    danger: tag.contains('CAC'),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 9),

          const Divider(height: 1),

          const SizedBox(height: 5),

          // ====================================================
          // Patient Chart Action
          // ====================================================
          Align(
            alignment: Alignment.centerRight,

            child: TextButton(
              onPressed: canOpenPatient
                  ? () {
                      _showScheduleDetailMessage(
                        context,
                        '${data.patientName} 환자 차트 열기',
                      );
                    }
                  : null,

              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),

                minimumSize: Size.zero,

                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),

              child: const Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    '환자 차트',

                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(width: 5),

                  Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Schedule Detail Tag
// Schedule Detail 내부에서만 사용하는 Private Widget
// ============================================================

class _ScheduleDetailTag extends StatelessWidget {
  final String text;
  final bool danger;

  const _ScheduleDetailTag({required this.text, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? context.appDangerBackground
        : context.appSurfaceSoft;

    final foreground = danger ? AppColors.danger : context.appTextSecondary;

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

// ============================================================
// STEP 3. Temporary Message
// 추후 실제 Patient Routing 연결 시 제거 예정
// ============================================================

void _showScheduleDetailMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        duration: const Duration(milliseconds: 900),
      ),
    );
}
