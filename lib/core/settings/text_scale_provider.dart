import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// STEP 1. 앱 글자 크기 모드
// ============================================================

enum AppTextScaleMode { system, normal, large, extraLarge }

// ============================================================
// STEP 2. 글자 크기 모드 확장
// ============================================================

extension AppTextScaleModeExtension on AppTextScaleMode {
  String get label {
    switch (this) {
      case AppTextScaleMode.system:
        return '시스템 설정';

      case AppTextScaleMode.normal:
        return '보통';

      case AppTextScaleMode.large:
        return '크게';

      case AppTextScaleMode.extraLarge:
        return '아주 크게';
    }
  }

  double? get scale {
    switch (this) {
      case AppTextScaleMode.system:
        return null;

      case AppTextScaleMode.normal:
        return 1.0;

      case AppTextScaleMode.large:
        return 1.15;

      case AppTextScaleMode.extraLarge:
        return 1.30;
    }
  }
}

// ============================================================
// STEP 3. Text Scale Provider
// ============================================================

class TextScaleProvider extends ChangeNotifier {
  static const String _storageKey = 'app_text_scale_mode';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  AppTextScaleMode _mode = AppTextScaleMode.system;

  // ==========================================================
  // STEP 4. 현재 모드
  // ==========================================================

  AppTextScaleMode get mode => _mode;

  // ==========================================================
  // STEP 5. 시스템 설정 사용 여부
  // ==========================================================

  bool get useSystemScale {
    return _mode == AppTextScaleMode.system;
  }

  // ==========================================================
  // STEP 6. 현재 앱 확대 비율
  // ==========================================================

  double? get scale => _mode.scale;

  // ==========================================================
  // STEP 7. 저장된 설정 불러오기
  // ==========================================================

  Future<void> load() async {
    final savedMode = await _preferences.getString(_storageKey);

    if (savedMode == null) {
      return;
    }

    for (final mode in AppTextScaleMode.values) {
      if (mode.name == savedMode) {
        _mode = mode;
        notifyListeners();
        return;
      }
    }
  }

  // ==========================================================
  // STEP 8. 글자 크기 변경 및 저장
  // ==========================================================

  Future<void> setMode(AppTextScaleMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;

    notifyListeners();

    await _preferences.setString(_storageKey, mode.name);
  }

  // ==========================================================
  // STEP 9. 글자 크기 단계 순환
  // 시스템 → 크게 → 아주 크게 → 시스템
  // ==========================================================

  Future<void> cycleMode() async {
    final AppTextScaleMode nextMode;

    switch (_mode) {
      case AppTextScaleMode.system:
        nextMode = AppTextScaleMode.large;
        break;

      // 기존에 저장된 normal 값이 있을 경우
      // 바로 large 단계로 이동
      case AppTextScaleMode.normal:
        nextMode = AppTextScaleMode.large;
        break;

      case AppTextScaleMode.large:
        nextMode = AppTextScaleMode.extraLarge;
        break;

      case AppTextScaleMode.extraLarge:
        nextMode = AppTextScaleMode.system;
        break;
    }

    await setMode(nextMode);
  }
}
