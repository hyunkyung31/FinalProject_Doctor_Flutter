import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/calendar/presentation/staff_schedule_page.dart';
import '../../features/patients/presentation/patients_page.dart';
import '../../features/appointments/presentation/appointments_page.dart';
import '../../features/examinations/presentation/examinations_page.dart';
import '../../features/imaging/presentation/imaging_page.dart';
import '../../features/ai/presentation/ai_page.dart';
import '../../features/consult/presentation/consultation_page.dart';
import '../widgets/feature_placeholder_page.dart';
import 'app_routes.dart';

// ============================================================
// STEP 1. Application Router
// ============================================================

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,

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

    // ========================================================
    // Examinations
    // ========================================================
    GoRoute(
      path: AppRoutes.examinations,
      builder: (context, state) {
        return const ExaminationsPage();
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
        return const FeaturePlaceholderPage(
          title: '설정',
          selectedIndex: -1,
          icon: Icons.settings_outlined,
        );
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
