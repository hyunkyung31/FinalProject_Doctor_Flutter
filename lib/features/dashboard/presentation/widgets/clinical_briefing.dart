import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/access_control.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Clinical Briefing
// BOMI Clinical Assistant
// 우선 확인 환자 버튼은 외부 Callback으로 연결
// ============================================================

class ClinicalBriefing extends StatelessWidget {
  final VoidCallback onPriorityPressed;

  const ClinicalBriefing({super.key, required this.onPriorityPressed});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isDoctor = auth.role == UserRole.doctor;

    // ==========================================================
    // 역할별 Briefing Message
    // ==========================================================

    final message = '오늘 우선 검토가 필요한 환자와 임상 결과를 정리했습니다.';

    final description = isDoctor
        ? '주요 임상 이상과 AI·CDSS 결과를 함께 반영했습니다.'
        : '환자 상태와 검사 진행 정보를 함께 반영했습니다.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,

        borderRadius: BorderRadius.circular(AppRadius.large),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // ====================================================
          // BOMI Clinical Assistant
          // ====================================================
          Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              SizedBox(
                width: 54,
                height: 54,

                child: ClipOval(
                  child: Image.asset(
                    'assets/images/bomi_doctor_profile.png',

                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surface,

                        alignment: Alignment.center,

                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.navy,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'BOMI ASSISTANT',

                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ====================================================
          // Briefing Content
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'CLINICAL BRIEFING',

                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navyLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          // ====================================================
          // Priority Patient Action
          // ====================================================
          OutlinedButton.icon(
            onPressed: onPriorityPressed,

            icon: const Icon(Icons.priority_high_rounded, size: 16),

            label: const Text('확인'),

            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: AppColors.surface,

              side: const BorderSide(color: AppColors.border),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}
