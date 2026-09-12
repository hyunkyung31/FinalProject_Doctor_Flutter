import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/access_control.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Continue Work Section
// 최근 진행 중인 업무 Preview
// ============================================================

class ContinueWorkSection extends StatelessWidget {
  final double width;
  final bool isLargeText;

  const ContinueWorkSection({
    super.key,
    required this.width,
    required this.isLargeText,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isDoctor = auth.role == UserRole.doctor;

    // ==========================================================
    // 반응형 Column 개수
    // ==========================================================

    int columns;

    if (isLargeText) {
      columns = width >= 900 ? 2 : 1;
    } else {
      columns = width >= 900
          ? 3
          : width >= 620
          ? 2
          : 1;
    }

    const gap = 12.0;

    final itemWidth = (width - ((columns - 1) * gap)) / columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ======================================================
        // Header
        // ======================================================
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'CONTINUE WORK',

                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 9),

        // ======================================================
        // Recent Work Cards
        // ======================================================
        Wrap(
          spacing: gap,
          runSpacing: 10,

          children: [
            // ==================================================
            // 최근 환자 차트
            // ==================================================
            SizedBox(
              width: itemWidth,

              child: const _ContinueWorkCard(
                icon: Icons.person_outline_rounded,

                title: '김OO 환자 차트',

                description: 'CCTA 결과 상담 · 최근 열람',

                lastActivity: '최근 열람 · 8분 전',
              ),
            ),

            // ==================================================
            // AI / 검사 결과
            // ==================================================
            SizedBox(
              width: itemWidth,

              child: _ContinueWorkCard(
                icon: Icons.auto_awesome_outlined,

                title: isDoctor ? '박OO AI 결과 검토' : '박OO 검사 결과 확인',

                description: isDoctor ? '검토 진행 중 · HIGH' : '검사 상태 업데이트 필요',

                lastActivity: isDoctor ? '마지막 작업 · 14분 전' : '최근 확인 · 12분 전',
              ),
            ),

            // ==================================================
            // 보고서 / 환자 기록
            // ==================================================
            SizedBox(
              width: itemWidth,

              child: _ContinueWorkCard(
                icon: Icons.description_outlined,

                title: isDoctor ? '최OO 보고서 작성' : '이OO 환자 기록',

                description: isDoctor ? '임시 저장 · 작성 중' : '최근 업데이트',

                lastActivity: isDoctor ? '마지막 저장 · 32분 전' : '업데이트 · 25분 전',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// STEP 2. Continue Work Card
// Continue Work 내부에서만 사용하는 Private Widget
// ============================================================

class _ContinueWorkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String lastActivity;

  const _ContinueWorkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.lastActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,

      borderRadius: BorderRadius.circular(AppRadius.medium),

      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),

        onTap: () {
          _showContinueWorkMessage(context, '$title 열기');
        },

        child: Container(
          constraints: const BoxConstraints(minHeight: 76),

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),

            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),

          child: Row(
            children: [
              // ==================================================
              // Icon
              // ==================================================
              Container(
                width: 36,
                height: 36,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,

                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),

                child: Icon(icon, size: 18, color: AppColors.navy),
              ),

              const SizedBox(width: 11),

              // ==================================================
              // Content
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ==============================================
                    // Last Activity
                    // ==============================================
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.textDisabled,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            lastActivity,

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Continue Work 임시 메시지
// 추후 실제 Routing 연결 시 삭제 예정
// ============================================================

void _showContinueWorkMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
}
