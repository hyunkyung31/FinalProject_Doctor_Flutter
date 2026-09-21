import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/staff_login_page.dart';
import '../../features/auth/presentation/staff_profile_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/calendar/data/services/schedule_service.dart';
import '../../features/calendar/presentation/staff_schedule_page.dart';
import '../../features/patients/presentation/patients_page.dart';
import '../../features/appointments/presentation/appointments_page.dart';
import '../../features/examinations/presentation/examinations_page.dart';
import '../../features/imaging/presentation/imaging_page.dart';
import '../../features/ai/presentation/ai_page.dart';
import '../../features/consult/presentation/consultation_page.dart';
import '../../features/settings/presentation/settings_page.dart';

import '../auth/auth_provider.dart';
import '../network/api_client.dart';
import '../widgets/feature_placeholder_page.dart';

import 'app_routes.dart';

// ============================================================
// 로그인 후 의료진 일정 사전 로딩
// ============================================================

Future<void> _prefetchSchedules(ApiClient apiClient) async {
  try {
    await ScheduleService(apiClient: apiClient).fetchSchedules();

    debugPrint('[SCHEDULE PREFETCH] 완료');
  } catch (error) {
    // 일정 Prefetch 실패가 로그인/대시보드 진입을 막으면 안 됨
    debugPrint('[SCHEDULE PREFETCH] 실패: $error');
  }
}

// ============================================================
// STEP 1. Application Router
// ============================================================

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  // ==========================================================
  // STEP 2. Authentication Route Guard
  // ==========================================================
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();

    final isAuthenticated = auth.isAuthenticated;

    final isLoginPage = state.matchedLocation == AppRoutes.login;

    // ========================================================
    // 로그인하지 않은 사용자
    // 보호 화면 접근 시 로그인 페이지로 이동
    // ========================================================

    if (!isAuthenticated) {
      if (!isLoginPage) {
        return AppRoutes.login;
      }

      return null;
    }

    // ========================================================
    // 이미 로그인한 사용자
    // 로그인 화면 재접근 시 Dashboard 이동
    // ========================================================

    if (isLoginPage) {
      return AppRoutes.dashboard;
    }

    return null;
  },

  routes: [
    // ========================================================
    // Root
    // ========================================================
    GoRoute(
      path: '/',
      redirect: (context, state) {
        return AppRoutes.dashboard;
      },
    ),

    // ========================================================
    // Login
    // ========================================================
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) {
        return StaffLoginPage(
          onLoginSuccess: () {
            final apiClient = context.read<ApiClient>();

            // ====================================================
            // 로그인 완료 후 일정 사전 로딩
            // Dashboard 진입은 기다리지 않음
            // ====================================================

            unawaited(_prefetchSchedules(apiClient));

            context.go(AppRoutes.dashboard);
          },
        );
      },
    ),

    // ========================================================
    // Staff Profile
    // ========================================================
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) {
        return const StaffProfilePage();
      },
    ),

    // ========================================================
    // Dashboard
    // ========================================================
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) {
        return const DashboardPage();
      },
    ),

    // ========================================================
    // Patients
    // ========================================================
    GoRoute(
      path: AppRoutes.patients,
      builder: (context, state) {
        return const PatientsPage();
      },
    ),

    // ========================================================
    // Appointments
    // ========================================================
    GoRoute(
      path: AppRoutes.appointments,
      builder: (context, state) {
        return const AppointmentsPage();
      },
    ),

    // ============================================================
    // 검사 관리
    // 환자 상세 > 검사 이력 화면에서 전달된 Context 지원
    // ============================================================
    GoRoute(
      path: AppRoutes.examinations,
      builder: (context, state) {
        final query = state.uri.queryParameters;

        final patientId = int.tryParse(query['patientId'] ?? '');

        final encounterId = int.tryParse(query['encounterId'] ?? '');

        final orderId = int.tryParse(query['orderId'] ?? '');

        final openCreateOrder = query['openCreateOrder'] == 'true';

        return ExaminationsPage(
          initialPatientId: patientId,
          initialEncounterId: encounterId,
          initialOrderId: orderId,
          openCreateOrder: openCreateOrder,
        );
      },
    ),

    // ========================================================
    // Imaging
    // ========================================================
    GoRoute(
      path: AppRoutes.imaging,
      builder: (context, state) {
        return const ImagingPage();
      },
    ),

    // ========================================================
    // AI
    // ========================================================
    GoRoute(
      path: AppRoutes.ai,
      builder: (context, state) {
        return const AiPage();
      },
    ),

    // ========================================================
    // CDSS
    // ========================================================
    GoRoute(
      path: AppRoutes.cdss,
      builder: (context, state) {
        return const FeaturePlaceholderPage(
          title: 'CDSS',
          selectedIndex: 6,
          icon: Icons.health_and_safety_outlined,
        );
      },
    ),

    // ========================================================
    // Consult
    // ========================================================
    GoRoute(
      path: AppRoutes.consult,
      builder: (context, state) {
        return const ConsultationPage();
      },
    ),

    // ========================================================
    // Calendar
    // ========================================================
    GoRoute(
      path: AppRoutes.calendar,
      builder: (context, state) => const StaffSchedulePage(),
    ),

    // ========================================================
    // Chat
    // Sidebar가 아닌 Top Bar에서 진입
    // ========================================================
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        return const FeaturePlaceholderPage(
          title: '채팅',
          selectedIndex: -1,
          icon: Icons.chat_bubble_outline_rounded,
        );
      },
    ),

    // ========================================================
    // Settings
    // ========================================================
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) {
        return const SettingsPage();
      },
    ),
  ],

  // ==========================================================
  // Route Error
  // ==========================================================
  errorBuilder: (context, state) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          '페이지를 찾을 수 없습니다.\n${state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  },
);
