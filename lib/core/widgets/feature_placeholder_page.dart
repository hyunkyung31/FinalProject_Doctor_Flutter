import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_shell.dart';

// ============================================================
// STEP 1. Feature Placeholder Page
// 실제 기능 화면 구현 전 Route 테스트용
// ============================================================

class FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final IconData icon;

  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: title,
      selectedIndex: selectedIndex,
      body: Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Icon(icon, size: 28, color: AppColors.navy),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              '기능 화면을 준비하고 있습니다.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
