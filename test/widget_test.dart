import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_doctor/core/auth/auth_provider.dart';
import 'package:flutter_doctor/core/auth/auth_service.dart';
import 'package:flutter_doctor/core/network/api_client.dart';
import 'package:flutter_doctor/core/network/api_endpoints.dart';
import 'package:flutter_doctor/core/settings/text_scale_provider.dart';
import 'package:flutter_doctor/main.dart';

// ============================================================
// STEP 1. CardioAI Widget Smoke Test
// ============================================================

void main() {
  testWidgets('CardioAI 앱이 정상적으로 생성된다.', (WidgetTester tester) async {
    // ========================================================
    // API Client
    // ========================================================

    final apiClient = ApiClient(baseUrl: ApiEndpoints.baseUrl);

    // ========================================================
    // Auth Service
    // ========================================================

    final authService = AuthService(apiClient: apiClient);

    // ========================================================
    // Auth Provider
    // 테스트에서는 실제 로그인 요청을 하지 않음
    // ========================================================

    final authProvider = AuthProvider(authService: authService);

    // ========================================================
    // Text Scale Provider
    // ========================================================

    final textScaleProvider = TextScaleProvider();

    // ========================================================
    // App Build
    // ========================================================

    await tester.pumpWidget(
      CardioAiApp(
        textScaleProvider: textScaleProvider,
        apiClient: apiClient,
        authProvider: authProvider,
      ),
    );

    await tester.pump();

    // ========================================================
    // 앱 생성 확인
    // ========================================================

    expect(find.text('대시보드'), findsWidgets);
  });
}
