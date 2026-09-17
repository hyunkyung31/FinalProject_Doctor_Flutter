import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'staff_user.dart';

// ============================================================
// STEP 1. Auth Session
// ============================================================

class AuthSession {
  final String accessToken;
  final String? refreshToken;

  const AuthSession({required this.accessToken, this.refreshToken});
}

// ============================================================
// STEP 2. Authentication Service
// ============================================================

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  // ==========================================================
  // STEP 3. 의료진 로그인
  // POST /auth/staff/login/
  // ==========================================================

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.staffLogin,
      data: {
        'username': username,
        'password': password,

        // ======================================================
        // Swagger에서 실제 로그인 성공 확인한 값
        // ======================================================
        'client_type': 'FLUTTER_STAFF',
        'platform': 'ANDROID',
        'device_id': 'emulator',
        'device_name': 'Android Emulator',
      },
    );

    if (response.data is! Map) {
      throw const FormatException('로그인 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final accessToken = data['access']?.toString();
    final refreshToken = data['refresh']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('로그인 응답에 access token이 없습니다.');
    }

    // ==========================================================
    // 이후 모든 Dio 요청에 JWT 자동 적용
    // ==========================================================

    apiClient.setAccessToken(accessToken);

    return AuthSession(accessToken: accessToken, refreshToken: refreshToken);
  }

  // ==========================================================
  // STEP 4. 현재 로그인 의료진 조회
  // GET /staff/me/
  // ==========================================================

  Future<StaffUser> getCurrentUser() async {
    final response = await apiClient.dio.get(ApiEndpoints.staffMe);

    if (response.data is! Map) {
      throw const FormatException('현재 사용자 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    return StaffUser.fromJson(data);
  }
}
