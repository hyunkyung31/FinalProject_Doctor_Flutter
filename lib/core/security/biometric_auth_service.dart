import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

// ============================================================
// STEP 1. Biometric Authentication Service
// ============================================================

class BiometricAuthService {
  final LocalAuthentication _localAuthentication;

  BiometricAuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  // ============================================================
  // STEP 2. 등록된 생체인증 사용 가능 여부
  // ============================================================

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;

      if (!canCheck) {
        return false;
      }

      final availableBiometrics = await _localAuthentication
          .getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } on LocalAuthException catch (error) {
      debugPrint('[BIOMETRIC] 사용 가능 여부 확인 실패: ${error.code}');

      return false;
    } catch (error) {
      debugPrint('[BIOMETRIC] 사용 가능 여부 확인 오류: $error');

      return false;
    }
  }

  // ============================================================
  // STEP 3. 생체인증 실행
  // ============================================================

  Future<bool> authenticate({String reason = 'DUGN 의료진 인증을 진행해주세요.'}) async {
    try {
      final available = await isAvailable();

      if (!available) {
        debugPrint('[BIOMETRIC] 등록된 생체인증 정보가 없습니다.');

        return false;
      }

      final authenticated = await _localAuthentication.authenticate(
        localizedReason: reason,

        // PIN / Pattern 대신 실제 생체인증만 허용
        biometricOnly: true,

        // 인증 중 앱 lifecycle 변경에 대응
        persistAcrossBackgrounding: true,
      );

      debugPrint(
        authenticated ? '[BIOMETRIC] 인증 성공' : '[BIOMETRIC] 인증 취소 또는 실패',
      );

      return authenticated;
    } on LocalAuthException catch (error) {
      debugPrint('[BIOMETRIC] 인증 실패: ${error.code}');

      return false;
    } catch (error) {
      debugPrint('[BIOMETRIC] 인증 오류: $error');

      return false;
    }
  }

  // ============================================================
  // STEP 4. 진행 중 인증 취소
  // ============================================================

  Future<void> cancelAuthentication() async {
    try {
      await _localAuthentication.stopAuthentication();
    } catch (error) {
      debugPrint('[BIOMETRIC] 인증 취소 실패: $error');
    }
  }
}
