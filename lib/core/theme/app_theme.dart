import 'package:flutter/material.dart';

// ============================================================
// STEP 1. CardioAI Color System
// Figma와 Flutter에서 동일하게 사용할 기본 컬러
// ============================================================

class AppColors {
  AppColors._();

  // ----------------------------------------------------------
  // Brand
  // ----------------------------------------------------------

  static const Color navy = Color(0xFF17324D);

  static const Color navyLight = Color(0xFF294E6D);

  static const Color primaryBlue = Color(0xFF3D6F98);

  static const Color secondaryBlue = Color(0xFF6689A8);

  // ----------------------------------------------------------
  // Background / Surface
  // ----------------------------------------------------------

  static const Color background = Color(0xFFF5F7FA);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceSoft = Color(0xFFEDF3F7);

  static const Color border = Color(0xFFE0E6EC);

  // ----------------------------------------------------------
  // Text
  // ----------------------------------------------------------

  static const Color textPrimary = Color(0xFF1F2D3D);

  static const Color textSecondary = Color(0xFF5F6C78);

  static const Color textDisabled = Color(0xFFA8B1BA);

  // ----------------------------------------------------------
  // Status
  // ----------------------------------------------------------

  static const Color danger = Color(0xFFC84D4D);

  static const Color dangerBackground = Color(0xFFFFEEEE);

  static const Color warning = Color(0xFFB47B2C);

  static const Color warningBackground = Color(0xFFFFF4DF);

  static const Color success = Color(0xFF3D8065);

  static const Color successBackground = Color(0xFFEAF6F0);

  // ----------------------------------------------------------
  // RBAC / Disabled
  // ----------------------------------------------------------

  static const Color disabledBackground = Color(0xFFF1F3F5);

  static const Color disabledForeground = Color(0xFF98A2AC);
}

// ============================================================
// STEP 2. 공통 Radius
// Figma Component Radius와 동일하게 사용
// ============================================================

class AppRadius {
  AppRadius._();

  static const double small = 8;

  static const double medium = 12;

  static const double large = 16;

  static const double round = 999;
}

// ============================================================
// STEP 3. 공통 Spacing
// Figma Auto Layout과 맞추기 위한 기본 간격
// ============================================================

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;

  static const double sm = 8;

  static const double md = 12;

  static const double lg = 16;

  static const double xl = 24;

  static const double xxl = 32;
}

// ============================================================
// STEP 4. CardioAI Theme
// ============================================================

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: colorScheme.copyWith(
        primary: AppColors.navy,
        secondary: AppColors.primaryBlue,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),

      // ========================================================
      // Text Theme
      // ========================================================
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),

        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),

        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      // ========================================================
      // Card
      // ========================================================
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),

          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ========================================================
      // Divider
      // ========================================================
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // Filled Button
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,

          disabledBackgroundColor: AppColors.disabledBackground,

          disabledForegroundColor: AppColors.disabledForeground,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),

          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ========================================================
      // Outlined Button
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,

          minimumSize: const Size(0, 48),

          side: const BorderSide(color: AppColors.border),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),

      // ========================================================
      // Icon
      // ========================================================
      iconTheme: const IconThemeData(color: AppColors.navy, size: 22),

      // ========================================================
      // Tooltip
      // RBAC 비활성 버튼 안내 등에 사용
      // ========================================================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),

        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),

      // ========================================================
      // SnackBar
      // ========================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,

        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
