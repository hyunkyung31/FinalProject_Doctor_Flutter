import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// STEP 1. App Theme Mode
// ============================================================

enum AppThemeMode { system, light, dark }

// ============================================================
// STEP 2. Theme Mode Provider
// ============================================================

class ThemeModeProvider extends ChangeNotifier {
  static const String _storageKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  // ==========================================================
  // Flutter ThemeMode 변환
  // ==========================================================

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;

      case AppThemeMode.dark:
        return ThemeMode.dark;

      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // ==========================================================
  // 저장된 화면 모드 불러오기
  // ==========================================================

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    final savedMode = preferences.getString(_storageKey);

    switch (savedMode) {
      case 'light':
        _mode = AppThemeMode.light;
        break;

      case 'dark':
        _mode = AppThemeMode.dark;
        break;

      case 'system':
      default:
        _mode = AppThemeMode.system;
        break;
    }

    notifyListeners();
  }

  // ==========================================================
  // 화면 모드 변경
  // ==========================================================

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_storageKey, mode.name);
  }
}
