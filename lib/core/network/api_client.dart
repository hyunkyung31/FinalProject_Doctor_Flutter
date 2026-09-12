import 'package:dio/dio.dart';

// ============================================================
// STEP 1. API Client
// Django REST API 공통 Dio Client
// ============================================================

class ApiClient {
  final Dio dio;

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
      );

  // ==========================================================
  // JWT Access Token 설정
  // ==========================================================

  void setAccessToken(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) {
      dio.options.headers.remove('Authorization');

      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  // ==========================================================
  // JWT 제거
  // ==========================================================

  void clearAccessToken() {
    dio.options.headers.remove('Authorization');
  }
}
