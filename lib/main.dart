import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
import 'core/router/app_router.dart';
import 'core/settings/text_scale_provider.dart';
import 'core/theme/app_theme.dart';

import 'features/calendar/data/services/schedule_service.dart';

// ============================================================
// STEP 0. 의료진 일정 사전 로딩
// ============================================================

Future<void> _prefetchSchedules(ApiClient apiClient) async {
  try {
    await ScheduleService(apiClient: apiClient).fetchSchedules();

    debugPrint('[SCHEDULE PREFETCH] 완료');
  } catch (error) {
    // 일정 Prefetch 실패가 앱 실행 자체를 막으면 안 됨
    debugPrint('[SCHEDULE PREFETCH] 실패: $error');
  }
}

// ============================================================
// STEP 1. Application Entry Point
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // Text Scale
  // ==========================================================

  final textScaleProvider = TextScaleProvider();

  await textScaleProvider.load();

  // ==========================================================
  // API Client
  // 앱 전체에서 하나의 ApiClient 인스턴스 사용
  // ==========================================================

  final apiClient = ApiClient(baseUrl: ApiEndpoints.baseUrl);

  // ==========================================================
  // Auth
  // ==========================================================

  final authService = AuthService(apiClient: apiClient);

  final authProvider = AuthProvider(authService: authService);

  // ==========================================================
  // 개발용 로그인 정보
  //
  // 소스코드에 ID / Password를 저장하지 않고
  // flutter run --dart-define 으로 전달
  // ==========================================================

  const username = String.fromEnvironment('STAFF_USERNAME');

  const password = String.fromEnvironment('STAFF_PASSWORD');

  // ==========================================================
  // 의료진 로그인
  // ==========================================================

  if (username.isNotEmpty && password.isNotEmpty) {
    final success = await authProvider.login(
      username: username,
      password: password,
    );

    debugPrint(success ? '[AUTH] 의료진 로그인 성공' : '[AUTH] 의료진 로그인 실패');

    // ========================================================
    // 로그인 성공 후 일정 API 사전 로딩
    //
    // await 하지 않음
    // → 대시보드 실행과 동시에 백그라운드에서 일정 조회
    // → 일정 페이지 첫 진입 시 캐시 활용
    // ========================================================

    if (success) {
      unawaited(_prefetchSchedules(apiClient));
    }
  } else {
    debugPrint(
      '[AUTH] STAFF_USERNAME / STAFF_PASSWORD가 '
      '설정되지 않았습니다.',
    );
  }

  // ==========================================================
  // Application Start
  // ==========================================================

  runApp(
    CardioAiApp(
      textScaleProvider: textScaleProvider,
      apiClient: apiClient,
      authProvider: authProvider,
    ),
  );
}

// ============================================================
// STEP 2. Root Application
// ============================================================

class CardioAiApp extends StatelessWidget {
  final TextScaleProvider textScaleProvider;

  final ApiClient apiClient;

  final AuthProvider authProvider;

  const CardioAiApp({
    super.key,
    required this.textScaleProvider,
    required this.apiClient,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ======================================================
        // API Client
        // ======================================================
        Provider<ApiClient>.value(value: apiClient),

        // ======================================================
        // Auth Provider
        // ======================================================
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        // ======================================================
        // Text Scale Provider
        // ======================================================
        ChangeNotifierProvider<TextScaleProvider>.value(
          value: textScaleProvider,
        ),
      ],

      child: Consumer<TextScaleProvider>(
        builder: (context, textScale, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,

            title: 'CardioAI',

            theme: AppTheme.light,

            routerConfig: appRouter,

            // ==================================================
            // 앱 전체 Text Scale 적용
            // ==================================================
            builder: (context, child) {
              if (child == null) {
                return const SizedBox.shrink();
              }

              // ==================================================
              // 시스템 글자 크기 사용
              // ==================================================

              if (textScale.useSystemScale) {
                return child;
              }

              final mediaQuery = MediaQuery.of(context);

              // ==================================================
              // 앱 설정 글자 크기 사용
              // ==================================================

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(textScale.scale ?? 1.0),
                ),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
