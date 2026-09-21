import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// STEP 1. Authentication Storage
// Refresh Token은 Secure Storage에 저장
// 자동 로그인 설정은 SharedPreferences 사용
// ============================================================

class AuthStorage {
  static const String _refreshTokenKey = 'auth_refresh_token';

  static const String _autoLoginKey = 'settings_auto_login';

  final FlutterSecureStorage _secureStorage;

  const AuthStorage({this._secureStorage = const FlutterSecureStorage()});

  // ==========================================================
  // STEP 2. 자동 로그인 설정 확인
  // SettingsPage와 동일한 SharedPreferences Key 사용
  // ==========================================================

  Future<bool> isAutoLoginEnabled() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_autoLoginKey) ?? true;
  }

  // ==========================================================
  // STEP 3. Refresh Token 저장
  // ==========================================================

  Future<void> saveRefreshToken(String refreshToken) async {
    if (refreshToken.trim().isEmpty) {
      return;
    }

    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // ==========================================================
  // STEP 4. Refresh Token 조회
  // ==========================================================

  Future<String?> readRefreshToken() async {
    final token = await _secureStorage.read(key: _refreshTokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token;
  }

  // ==========================================================
  // STEP 5. Refresh Token 삭제
  // ==========================================================

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
