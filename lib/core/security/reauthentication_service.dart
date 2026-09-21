import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

// ============================================================
// STEP 1. Reauthentication Result
// Backend 재인증 성공 응답
// ============================================================

class ReauthenticationResult {
  final bool reauthenticated;
  final String authMethod;
  final String reauthToken;
  final int expiresIn;

  const ReauthenticationResult({
    required this.reauthenticated,
    required this.authMethod,
    required this.reauthToken,
    required this.expiresIn,
  });

  factory ReauthenticationResult.fromJson(Map<String, dynamic> json) {
    return ReauthenticationResult(
      reauthenticated: json['reauthenticated'] == true,
      authMethod: json['auth_method']?.toString() ?? '',
      reauthToken: json['reauth_token']?.toString() ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }
}

// ============================================================
// STEP 2. Reauthentication Exception
// ============================================================

class ReauthenticationException implements Exception {
  final String message;

  const ReauthenticationException(this.message);

  @override
  String toString() => message;
}

// ============================================================
// STEP 3. Reauthentication Service
// ============================================================

class ReauthenticationService {
  final ApiClient apiClient;

  const ReauthenticationService({required this.apiClient});

  // ============================================================
  // STEP 4. Password Reauthentication
  //
  // POST /staff/reauthenticate/
  //
  // Request:
  // {
  //   "auth_method": "PASSWORD",
  //   "credential": "..."
  // }
  //
  // Success:
  // {
  //   "reauthenticated": true,
  //   "auth_method": "PASSWORD",
  //   "reauth_token": "...",
  //   "expires_in": 300
  // }
  // ============================================================

  Future<ReauthenticationResult> verifyPassword({
    required String password,
  }) async {
    final credential = password.trim();

    if (credential.isEmpty) {
      throw const ReauthenticationException('비밀번호를 입력해주세요.');
    }

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.staffReauthenticate,
        data: {'auth_method': 'PASSWORD', 'credential': credential},
      );

      if (response.data is! Map) {
        throw const ReauthenticationException('재인증 응답 형식이 올바르지 않습니다.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      final result = ReauthenticationResult.fromJson(data);

      if (!result.reauthenticated) {
        throw const ReauthenticationException('재인증에 실패했습니다.');
      }

      if (result.reauthToken.isEmpty) {
        throw const ReauthenticationException('재인증 토큰을 확인할 수 없습니다.');
      }

      if (result.expiresIn <= 0) {
        throw const ReauthenticationException('재인증 유효 시간을 확인할 수 없습니다.');
      }

      return result;
    } on ReauthenticationException {
      rethrow;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      final responseData = error.response?.data;

      // ========================================================
      // 잘못된 비밀번호
      // Backend 실제 응답:
      //
      // 401
      // {
      //   "detail": "비밀번호가 올바르지 않습니다."
      // }
      // ========================================================

      if (statusCode == 401) {
        if (responseData is Map && responseData['detail'] != null) {
          throw ReauthenticationException(responseData['detail'].toString());
        }

        throw const ReauthenticationException('비밀번호가 올바르지 않습니다.');
      }

      debugPrint(
        '[REAUTH] API 오류 '
        'status=$statusCode, '
        'data=$responseData',
      );

      throw const ReauthenticationException('재인증 요청 중 오류가 발생했습니다.');
    } catch (error) {
      debugPrint('[REAUTH] 예상하지 못한 오류: $error');

      throw const ReauthenticationException('재인증 중 오류가 발생했습니다.');
    }
  }
}
