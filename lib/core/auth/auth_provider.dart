import 'package:flutter/material.dart';

import 'access_control.dart';
import 'auth_service.dart';
import 'staff_user.dart';

// ============================================================
// 인증 상태 Provider
// ============================================================

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  AuthProvider({required this.authService});

  UserRole _role = UserRole.doctor;

  StaffUser? _currentUser;

  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  String? _refreshToken;
  String? _authError;

  String? _reauthToken;
  DateTime? _reauthExpiresAt;

  // ============================================================
  // 인증 상태
  // ============================================================

  bool get isAuthenticated => _isAuthenticated;

  bool get isAuthenticating => _isAuthenticating;

  String? get authError => _authError;

  String? get refreshToken => _refreshToken;

  String? get reauthToken {
    if (!hasValidReauthToken) {
      return null;
    }

    return _reauthToken;
  }

  DateTime? get reauthExpiresAt => _reauthExpiresAt;

  bool get hasValidReauthToken {
    if (_reauthToken == null || _reauthExpiresAt == null) {
      return false;
    }

    return DateTime.now().isBefore(_reauthExpiresAt!);
  }

  Duration get reauthRemaining {
    if (!hasValidReauthToken) {
      return Duration.zero;
    }

    return _reauthExpiresAt!.difference(DateTime.now());
  }

  // ============================================================
  // 현재 사용자 Role
  // ============================================================

  UserRole get role => _role;
  StaffUser? get currentUser => _currentUser;
  bool get isNurse => _role == UserRole.nurse;

  // ============================================================
  // STEP 4. Backend Role → Flutter Role 변환
  // ============================================================

  UserRole _parseRole(List<String> roles) {
    for (final role in roles) {
      switch (role.toUpperCase()) {
        case 'DOCTOR':
          return UserRole.doctor;

        case 'NURSE':
          return UserRole.nurse;
      }
    }

    throw UnsupportedError('지원하지 않는 의료진 Role입니다: ${roles.join(', ')}');
  }

  // ============================================================
  // STEP 4. 의료진 로그인
  // ============================================================

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isAuthenticating = true;
    _authError = null;

    clearReauthToken(notify: false);

    notifyListeners();

    try {
      final session = await authService.login(
        username: username,
        password: password,
      );

      _refreshToken = session.refreshToken;

      // ============================================================
      // 로그인 성공 후 현재 의료진 정보 조회
      // ============================================================

      final currentUser = await authService.getCurrentUser();

      debugPrint(
        '[AuthProvider] currentUser: '
        'id=${currentUser.id}, '
        'username=${currentUser.username}, '
        'status=${currentUser.status}, '
        'roles=${currentUser.roles}',
      );

      if (!currentUser.isActive) {
        authService.apiClient.clearAccessToken();

        throw StateError('비활성화된 의료진 계정입니다.');
      }

      _currentUser = currentUser;

      // ============================================================
      // 실제 Backend Role 적용
      // ============================================================

      _role = _parseRole(currentUser.roles);

      debugPrint('[AuthProvider] parsed role: $_role');

      _isAuthenticated = true;

      return true;
    } catch (error) {
      _isAuthenticated = false;
      _refreshToken = null;
      _currentUser = null;
      clearReauthToken(notify: false);

      _authError = error.toString();

      debugPrint('[AuthProvider] 로그인 실패: $error');

      return false;
    } finally {
      _isAuthenticating = false;

      notifyListeners();
    }
  }

  // ============================================================
  // STEP 5. 사용자 정보
  // ============================================================

  String get userName {
    return _currentUser?.username ?? '의료진';
  }

  String get position {
    return _role.label;
  }

  String get department {
    return '순환기내과';
  }

  // ============================================================
  // Permission 보유 여부 확인
  // ============================================================

  bool hasPermission(AppPermission permission) {
    return RolePermissions.can(_role, permission);
  }

  // ============================================================
  // 전체 Permission
  // ============================================================

  Set<AppPermission> get permissions {
    return RolePermissions.permissionsOf(_role);
  }

  void saveReauthToken({required String token, required int expiresInSeconds}) {
    if (token.trim().isEmpty || expiresInSeconds <= 0) {
      clearReauthToken();
      return;
    }

    _reauthToken = token;
    _reauthExpiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));

    notifyListeners();
  }

  void clearReauthToken({bool notify = true}) {
    _reauthToken = null;
    _reauthExpiresAt = null;

    if (notify) {
      notifyListeners();
    }
  }
}
