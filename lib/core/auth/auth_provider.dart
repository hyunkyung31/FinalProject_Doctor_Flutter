import 'package:flutter/material.dart';

import 'access_control.dart';
import 'auth_service.dart';
import 'staff_user.dart';
import 'auth_storage.dart';

// ============================================================
// 인증 상태 Provider
// ============================================================

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final AuthStorage authStorage;

  AuthProvider({required this.authService, required this.authStorage});

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
  // 과장 여부
  // Backend title 기준
  // ============================================================

  bool get isDepartmentHead {
    final title = _currentUser?.title.trim() ?? '';

    if (title.isEmpty) {
      return false;
    }

    return title.contains('과장');
  }

  // ============================================================
  // 화면 표시용 직책
  //
  // 일반 의사 → 의사
  // 간호사   → 간호사
  // 과장 의사 → 과장
  // ============================================================

  String get displayPosition {
    if (isDepartmentHead) {
      return '과장';
    }

    return _role.label;
  }

  // ============================================================
  // 휴무 승인 가능 여부
  // ============================================================

  bool get canApproveLeave {
    return isDepartmentHead;
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
      // 자동 로그인 설정에 따라 Refresh Token 보관
      // ============================================================

      final autoLoginEnabled = await authStorage.isAutoLoginEnabled();

      final refreshToken = session.refreshToken;

      if (autoLoginEnabled && refreshToken != null && refreshToken.isNotEmpty) {
        await authStorage.saveRefreshToken(refreshToken);
      } else {
        await authStorage.deleteRefreshToken();
      }

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

      // 저장된 Refresh Token 제거
      await authStorage.deleteRefreshToken();

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
  // 자동 로그인 세션 복원
  // 저장된 Refresh Token → Access Token 재발급 → 사용자 복원
  // ============================================================

  Future<bool> restoreSession() async {
    _isAuthenticating = true;
    _authError = null;

    notifyListeners();

    try {
      // ========================================================
      // 자동 로그인 설정 확인
      // ========================================================

      final autoLoginEnabled = await authStorage.isAutoLoginEnabled();

      if (!autoLoginEnabled) {
        await authStorage.deleteRefreshToken();

        return false;
      }

      // ========================================================
      // Secure Storage에서 Refresh Token 조회
      // ========================================================

      final storedRefreshToken = await authStorage.readRefreshToken();

      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return false;
      }

      // ========================================================
      // Refresh Token으로 새 Access / Refresh Token 발급
      // ========================================================

      final session = await authService.refreshSession(
        refreshToken: storedRefreshToken,
      );

      final newRefreshToken = session.refreshToken ?? storedRefreshToken;

      _refreshToken = newRefreshToken;

      // ========================================================
      // Backend가 새 Refresh Token을 반환하므로 교체 저장
      // ========================================================

      await authStorage.saveRefreshToken(newRefreshToken);

      // ========================================================
      // 현재 의료진 정보 복원
      // ========================================================

      final currentUser = await authService.getCurrentUser();

      if (!currentUser.isActive) {
        throw StateError('비활성화된 의료진 계정입니다.');
      }

      _currentUser = currentUser;

      _role = _parseRole(currentUser.roles);

      _isAuthenticated = true;

      clearReauthToken(notify: false);

      debugPrint(
        '[AuthProvider] 자동 로그인 성공: '
        '${currentUser.username}',
      );

      return true;
    } catch (error) {
      // ========================================================
      // 만료되거나 잘못된 Refresh Token은 폐기
      // ========================================================

      authService.apiClient.clearAccessToken();

      await authStorage.deleteRefreshToken();

      _refreshToken = null;
      _currentUser = null;

      _isAuthenticated = false;

      clearReauthToken(notify: false);

      _authError = null;

      debugPrint('[AuthProvider] 자동 로그인 실패: $error');

      return false;
    } finally {
      _isAuthenticating = false;

      notifyListeners();
    }
  }

  // ============================================================
  // Access Token 자동 갱신
  // 앱 사용 중 API 401 발생 시 호출
  // ============================================================

  Future<bool> refreshAccessToken() async {
    try {
      // ========================================================
      // 현재 메모리 Token 우선
      // 없으면 Secure Storage 확인
      // ========================================================

      final refreshToken =
          _refreshToken ?? await authStorage.readRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[AuthProvider] Refresh Token 없음');

        return false;
      }

      // ========================================================
      // Access / Refresh Token 재발급
      // ========================================================

      final session = await authService.refreshSession(
        refreshToken: refreshToken,
      );

      final newRefreshToken = session.refreshToken ?? refreshToken;

      _refreshToken = newRefreshToken;

      // ========================================================
      // 자동 로그인 ON일 때만 Secure Storage 갱신
      // ========================================================

      final autoLoginEnabled = await authStorage.isAutoLoginEnabled();

      if (autoLoginEnabled) {
        await authStorage.saveRefreshToken(newRefreshToken);
      } else {
        await authStorage.deleteRefreshToken();
      }

      debugPrint('[AuthProvider] Access Token 자동 갱신 완료');

      return true;
    } catch (error) {
      debugPrint('[AuthProvider] Access Token 자동 갱신 실패: $error');

      return false;
    }
  }

  // ============================================================
  // STEP 5. 의료진 로그아웃
  // ============================================================

  Future<void> logout() async {
    // ==========================================================
    // Access Token 제거
    // 이후 API 요청에 Authorization Header가 붙지 않음
    // ==========================================================

    authService.apiClient.clearAccessToken();

    // ==========================================================
    // 로그인 사용자 정보 초기화
    // ==========================================================

    _currentUser = null;

    // ==========================================================
    // 인증 상태 초기화
    // ==========================================================

    _isAuthenticated = false;
    _isAuthenticating = false;

    _refreshToken = null;
    _authError = null;

    // ==========================================================
    // 재인증 정보 초기화
    // ==========================================================

    clearReauthToken(notify: false);

    // ==========================================================
    // 기본 Role 초기화
    // ==========================================================

    _role = UserRole.doctor;

    debugPrint('[AuthProvider] 의료진 로그아웃 완료');

    notifyListeners();
  }

  // ============================================================
  // STEP 6. 사용자 표시 정보
  // ============================================================

  String get userName {
    final currentUser = _currentUser;

    if (currentUser == null) {
      return '의료진';
    }

    if (currentUser.name.trim().isNotEmpty) {
      return currentUser.name;
    }

    if (currentUser.username.trim().isNotEmpty) {
      return currentUser.username;
    }

    return '의료진';
  }

  String get accountName {
    return _currentUser?.username ?? '';
  }

  String get position {
    return _role.label;
  }

  String get department {
    final departmentName = _currentUser?.departmentName.trim();

    if (departmentName == null || departmentName.isEmpty) {
      return '소속 미지정';
    }

    return departmentName;
  }

  String get jobTitle {
    return _currentUser?.title ?? '';
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
