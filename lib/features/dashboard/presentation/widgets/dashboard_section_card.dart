import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Dashboard Common Section Card
// Dashboard 내부 여러 영역에서 공통으로 사용하는 카드
// ============================================================

class DashboardSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  final String? actionLabel;
  final VoidCallback? onAction;

  final Widget child;

  const DashboardSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              5, // 위 여백
              8,
              5, // 아래 여백
            ),
            child: Row(
              children: [
                // ==================================================
                // Title
                // ==================================================
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // ==================================================
                // Optional Action
                // ==================================================
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ======================================================
          // Content
          // ======================================================
          child,
        ],
      ),
    );
  }
}
