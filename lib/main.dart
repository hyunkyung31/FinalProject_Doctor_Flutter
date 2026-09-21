import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_storage.dart';
import 'core/security/app_security_guard.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/settings/text_scale_provider.dart';
import 'core/settings/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/data/services/schedule_service.dart';
import 'features/notifications/providers/notification_provider.dart';

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
  // Theme Mode
  // ==========================================================

  final themeModeProvider = ThemeModeProvider();

  await themeModeProvider.load();

  // ==========================================================
  // API Client
  // 앱 전체에서 하나의 ApiClient 인스턴스 사용
  // ==========================================================

  final apiClient = ApiClient(baseUrl: ApiEndpoints.baseUrl);

  // ==========================================================
  // Auth
  // ==========================================================

  final authService = AuthService(apiClient: apiClient);

  final authStorage = AuthStorage();

  final authProvider = AuthProvider(
    authService: authService,
    authStorage: authStorage,
  );

  // ==========================================================
  // API 401 세션 만료 처리 연결
  // ==========================================================

  apiClient.configureAuthHandling(
    onRefreshAccessToken: authProvider.refreshAccessToken,

    onSessionExpired: () async {
      debugPrint('[AUTH] 세션 만료 - 로그인 화면으로 이동');

      await authProvider.logout();

      appRouter.go(AppRoutes.login);
    },
  );
  // ==========================================================
  // 저장된 Refresh Token을 이용한 자동 로그인
  //
  // 생체 로그인이 활성화된 경우:
  // → 자동 복원하지 않음
  // → 로그인 화면에서 생체인증 성공 후 세션 복원
  // ==========================================================

  final preferences = await SharedPreferences.getInstance();

  final biometricLoginEnabled =
      preferences.getBool('settings_biometric_login') ?? false;

  final bool sessionRestored;

  if (biometricLoginEnabled) {
    sessionRestored = false;

    debugPrint('[AUTH] 생체 로그인 사용 중 - 로그인 화면에서 인증 대기');
  } else {
    sessionRestored = await authProvider.restoreSession();

    debugPrint(
      sessionRestored ? '[AUTH] 저장된 세션 복원 성공' : '[AUTH] 저장된 세션 없음 또는 복원 실패',
    );
  }

  // ==========================================================
  // 자동 로그인 성공 후 의료진 일정 사전 로딩
  // ==========================================================

  if (sessionRestored) {
    unawaited(
      ScheduleService(apiClient: apiClient)
          .fetchSchedules()
          .then((_) {
            debugPrint('[SCHEDULE PREFETCH] 자동 로그인 후 완료');
          })
          .catchError((Object error) {
            debugPrint('[SCHEDULE PREFETCH] 자동 로그인 후 실패: $error');
          }),
    );
  }

  // ==========================================================
  // Application Start
  // ==========================================================

  runApp(
    CardioAiApp(
      textScaleProvider: textScaleProvider,
      themeModeProvider: themeModeProvider,
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

  final ThemeModeProvider themeModeProvider;

  final ApiClient apiClient;

  final AuthProvider authProvider;

  const CardioAiApp({
    super.key,
    required this.textScaleProvider,
    required this.themeModeProvider,
    required this.apiClient,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // API Client
        Provider<ApiClient>.value(value: apiClient),

        // Auth Provider
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        // Text Scale Provider
        ChangeNotifierProvider<TextScaleProvider>.value(
          value: textScaleProvider,
        ),

        // Theme Mode Provider
        ChangeNotifierProvider<ThemeModeProvider>.value(
          value: themeModeProvider,
        ),

        // Notification Provider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(apiClient: apiClient),
        ),
      ],

      child: Consumer2<TextScaleProvider, ThemeModeProvider>(
        builder: (context, textScale, themeMode, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,

            title: 'DUGN',

            // ==================================================
            // Theme
            // ==================================================
            theme: AppTheme.light,

            darkTheme: AppTheme.dark,

            themeMode: themeMode.themeMode,

            // ==================================================
            // Router
            // ==================================================
            routerConfig: appRouter,

            // ==================================================
            // 앱 전체 Builder
            // - Text Scale
            // - 자동 잠금
            // - 백그라운드 화면 보호
            // ==================================================
            builder: (context, child) {
              if (child == null) {
                return const SizedBox.shrink();
              }

              Widget content = child;

              // ================================================
              // 앱 설정 글자 크기 사용
              // 시스템 글자 크기 사용 시에는 그대로 유지
              // ================================================

              if (!textScale.useSystemScale) {
                final mediaQuery = MediaQuery.of(context);

                content = MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(textScale.scale ?? 1.0),
                  ),
                  child: content,
                );
              }

              // ================================================
              // 앱 보안 Guard
              // - 자동 잠금
              // - 백그라운드 화면 보호
              // ================================================

              return AppSecurityGuard(child: content);
            },
          );
        },
      ),
    );
  }
}
