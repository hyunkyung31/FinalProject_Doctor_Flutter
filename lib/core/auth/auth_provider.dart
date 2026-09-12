import 'package:flutter/material.dart';

import 'access_control.dart';
import 'auth_service.dart';

// ============================================================
// STEP 1. 인증 상태 Provider
// ============================================================

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  AuthProvider({required this.authService});

  UserRole _role = UserRole.doctor;

  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  String? _refreshToken;
  String? _authError;

  // ============================================================
  // STEP 2. 인증 상태
  // ============================================================

  bool get isAuthenticated => _isAuthenticated;

  bool get isAuthenticating => _isAuthenticating;

  String? get authError => _authError;

  String? get refreshToken => _refreshToken;

  // ============================================================
  // STEP 3. 현재 사용자 Role
  // ============================================================

  UserRole get role => _role;

  // ============================================================
  // STEP 4. 의료진 로그인
  // ============================================================

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isAuthenticating = true;
    _authError = null;

    notifyListeners();

    try {
      final session = await authService.login(
        username: username,
        password: password,
      );

      _refreshToken = session.refreshToken;

      _isAuthenticated = true;

      return true;
    } catch (error) {
      _isAuthenticated = false;
      _refreshToken = null;

      _authError = error.toString();

      debugPrint('[AuthProvider] 로그인 실패: $error');

      return false;
    } finally {
      _isAuthenticating = false;

      notifyListeners();
    }
  }

  // ============================================================
  // STEP 5. 테스트용 사용자 정보
  // /staff/me 연결 전까지 유지
  // ============================================================

  String get userName {
    switch (_role) {
      case UserRole.doctor:
        return '김OO';

      case UserRole.nurse:
        return '박OO';
    }
  }

  String get position {
    switch (_role) {
      case UserRole.doctor:
        return '의사';

      case UserRole.nurse:
        return '간호사';
    }
  }

  String get department {
    return '순환기내과';
  }

  // ============================================================
  // STEP 6. Permission 보유 여부 확인
  // ============================================================

  bool hasPermission(AppPermission permission) {
    return RolePermissions.can(_role, permission);
  }

  // ============================================================
  // STEP 7. 전체 Permission
  // ============================================================

  Set<AppPermission> get permissions {
    return RolePermissions.permissionsOf(_role);
  }

  // ============================================================
  // STEP 8. 개발용 Role 변경
  // 실제 /staff/me 연결 후 제거 예정
  // ============================================================

  void switchRole(UserRole role) {
    if (_role == role) {
      return;
    }

    _role = role;

    notifyListeners();
  }
}
