import 'package:flutter/material.dart';

import 'app_theme.dart';

// ============================================================
// STEP 1. Context-aware Semantic Colors
//
// React 의료진 Web의 semantic token 구조를 Flutter에 적용합니다.
// 라이트 모드의 기존 색상은 그대로 유지하고,
// 다크 모드에서만 의료진 워크스테이션용 Soft Dark 색상을 사용합니다.
// ============================================================

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ==========================================================
  // Background / Surface
  // ==========================================================

  Color get appBackground =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get appSurface =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get appSurfaceSoft =>
      isDarkMode ? AppColors.darkSurfaceSoft : AppColors.surfaceSoft;

  // 카드 내부 선택 / Hover 영역
  Color get appSelection =>
      isDarkMode ? const Color(0xFF354A5B) : const Color(0xFFF8FAFC);

  // 비어있는 영역 / 약한 Panel
  Color get appPanelMuted =>
      isDarkMode ? const Color(0xFF25333F) : const Color(0xFFFAFBFC);

  // ==========================================================
  // Border
  // ==========================================================

  Color get appBorder => isDarkMode ? AppColors.darkBorder : AppColors.border;

  // ==========================================================
  // Text
  // ==========================================================

  Color get appTextPrimary =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get appTextSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get appTextDisabled =>
      isDarkMode ? AppColors.darkTextDisabled : AppColors.textDisabled;

  // ==========================================================
  // Brand / Accent
  // ==========================================================

  Color get appPrimary =>
      isDarkMode ? const Color(0xFF6EA8FF) : AppColors.primaryBlue;

  Color get appBrand => isDarkMode ? const Color(0xFF7CB4FF) : AppColors.navy;

  Color get appNavyLight =>
      isDarkMode ? const Color(0xFF42627C) : AppColors.navyLight;

  // ==========================================================
  // Status Background
  // 다크 모드에서 기존 밝은 pastel 배경이 뜨지 않도록 조정
  // ==========================================================

  Color get appDangerBackground =>
      isDarkMode ? const Color(0xFF4A2B30) : AppColors.dangerBackground;

  Color get appWarningBackground =>
      isDarkMode ? const Color(0xFF493A24) : AppColors.warningBackground;

  Color get appSuccessBackground =>
      isDarkMode ? const Color(0xFF213C33) : AppColors.successBackground;
}
