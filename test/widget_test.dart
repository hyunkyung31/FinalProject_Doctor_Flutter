import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doctor/core/settings/theme_mode_provider.dart';

import 'package:flutter_doctor/core/auth/auth_provider.dart';
import 'package:flutter_doctor/core/auth/auth_service.dart';
import 'package:flutter_doctor/core/auth/auth_storage.dart';
import 'package:flutter_doctor/core/network/api_client.dart';
import 'package:flutter_doctor/core/network/api_endpoints.dart';
import 'package:flutter_doctor/core/settings/text_scale_provider.dart';
import 'package:flutter_doctor/main.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:flutter_doctor/features/auth/presentation/staff_login_page.dart';

// ============================================================
// STEP 1. CardioAI Widget Smoke Test
// ============================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // STEP 2. SharedPreferences 테스트 환경 설정
  // ==========================================================

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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
    // ========================================================

    final authStorage = AuthStorage();

    final authProvider = AuthProvider(
      authService: authService,
      authStorage: authStorage,
    );

    // ========================================================
    // Text Scale Provider
    // ========================================================

    final textScaleProvider = TextScaleProvider();

    // ========================================================
    // Theme Mode Provider
    // ========================================================

    final themeModeProvider = ThemeModeProvider();

    // ========================================================
    // App Build
    // ========================================================

    await tester.pumpWidget(
      CardioAiApp(
        textScaleProvider: textScaleProvider,
        themeModeProvider: themeModeProvider,
        apiClient: apiClient,
        authProvider: authProvider,
      ),
    );

    // ========================================================
    // 로그인 화면 렌더링 대기
    // ========================================================

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ========================================================
    // 앱 생성 확인
    // ========================================================

    expect(find.byType(StaffLoginPage), findsOneWidget);
  });
}
