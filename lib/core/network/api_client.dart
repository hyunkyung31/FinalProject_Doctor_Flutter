import 'package:dio/dio.dart';

// ============================================================
// STEP 1. Auth Callback Type
// ============================================================

typedef RefreshAccessTokenCallback = Future<bool> Function();
typedef SessionExpiredCallback = Future<void> Function();

// ============================================================
// STEP 2. API Client
// Django REST API 공통 Dio Client
// ============================================================

class ApiClient {
  final Dio dio;

  RefreshAccessTokenCallback? _refreshAccessToken;
  SessionExpiredCallback? _onSessionExpired;

  Future<bool>? _refreshFuture;

  ApiClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _configureInterceptors();
  }

  // ==========================================================
  // STEP 3. 인증 처리 Callback 연결
  // ==========================================================

  void configureAuthHandling({
    required RefreshAccessTokenCallback onRefreshAccessToken,
    required SessionExpiredCallback onSessionExpired,
  }) {
    _refreshAccessToken = onRefreshAccessToken;
    _onSessionExpired = onSessionExpired;
  }

  // ==========================================================
  // STEP 4. JWT Access Token 설정
  // ==========================================================

  void setAccessToken(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) {
      dio.options.headers.remove('Authorization');

      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  // ==========================================================
  // STEP 5. JWT 제거
  // ==========================================================

  void clearAccessToken() {
    dio.options.headers.remove('Authorization');
  }

  // ==========================================================
  // STEP 6. Dio Interceptor
  // 401 발생 시 Access Token 자동 갱신
  // ==========================================================

  void _configureInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;

          final skipAuthRefresh =
              error.requestOptions.extra['skipAuthRefresh'] == true;

          final alreadyRetried =
              error.requestOptions.extra['authRetried'] == true;

          // ==================================================
          // 401이 아니거나
          // 로그인 / Refresh API이거나
          // 이미 재시도한 요청이면 그대로 전달
          // ==================================================

          if (statusCode != 401 ||
              skipAuthRefresh ||
              alreadyRetried ||
              _refreshAccessToken == null) {
            handler.next(error);
            return;
          }

          // ==================================================
          // Access Token 갱신
          // ==================================================

          final refreshed = await _runTokenRefresh();

          if (!refreshed) {
            await _handleSessionExpired();

            handler.next(error);
            return;
          }

          // ==================================================
          // 실패했던 요청 1회 재시도
          // ==================================================

          final requestOptions = error.requestOptions;

          requestOptions.extra['authRetried'] = true;

          final authorization = dio.options.headers['Authorization'];

          if (authorization != null) {
            requestOptions.headers['Authorization'] = authorization;
          } else {
            requestOptions.headers.remove('Authorization');
          }

          try {
            final response = await dio.fetch<dynamic>(requestOptions);

            handler.resolve(response);
          } on DioException catch (retryError) {
            if (retryError.response?.statusCode == 401) {
              await _handleSessionExpired();
            }

            handler.next(retryError);
          }
        },
      ),
    );
  }

  // ==========================================================
  // STEP 7. 동시에 여러 API가 401을 반환해도
  // Refresh 요청은 한 번만 실행
  // ==========================================================

  Future<bool> _runTokenRefresh() async {
    final existingFuture = _refreshFuture;

    if (existingFuture != null) {
      return existingFuture;
    }

    final callback = _refreshAccessToken;

    if (callback == null) {
      return false;
    }

    final future = callback();

    _refreshFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    }
  }

  // ==========================================================
  // STEP 8. Refresh까지 실패한 경우
  // ==========================================================

  Future<void> _handleSessionExpired() async {
    final callback = _onSessionExpired;

    if (callback == null) {
      return;
    }

    await callback();
  }
}
