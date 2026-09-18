import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../core/widgets/app_shell.dart';

import 'widgets/continue_work_section.dart';
import 'widgets/smart_queue_card.dart';
import 'widgets/clinical_briefing.dart';
import 'widgets/priority_patient_panel.dart';
import 'widgets/my_todo_section.dart';

import 'widgets/today_schedule/today_schedule_card.dart';

// ============================================================
// STEP 1. Dashboard Page
// ============================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      pageTitle: '대시보드',
      selectedIndex: 0,

      body: Container(
        color: context.appBackground,

        child: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 20),

          child: _ClinicalBriefingDashboard(),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 2. Clinical Briefing Dashboard
// ============================================================

class _ClinicalBriefingDashboard extends StatelessWidget {
  const _ClinicalBriefingDashboard();

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    final textScale = textScaler.scale(16) / 16;

    final isLargeText = textScale >= 1.25;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // Clinical Briefing
            // ==================================================
            ClinicalBriefing(
              onPriorityPressed: () {
                showPriorityPatientPanel(context);
              },
            ),

            const SizedBox(height: 14),

            // ==================================================
            // Main Clinical Dashboard
            // Patient Pulse / Smart Queue / Today Flow
            // ==================================================
            _ClinicalDashboardGrid(width: width, isLargeText: isLargeText),

            const SizedBox(height: 14),

            // ==================================================
            // My todo
            // ==================================================
            const MyTodoSection(),

            const SizedBox(height: 14),

            // ==================================================
            // Continue Work
            // ==================================================
            ContinueWorkSection(width: width, isLargeText: isLargeText),
          ],
        );
      },
    );
  }
}

// ============================================================
// STEP 5. Responsive Clinical Dashboard Grid
//
// 기본 / 115% → Today Schedule + Smart Queue 2열
// 130% 이상 → 세로 1열
// ============================================================

class _ClinicalDashboardGrid extends StatelessWidget {
  final double width;
  final bool isLargeText;

  const _ClinicalDashboardGrid({
    required this.width,
    required this.isLargeText,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // 넓은 태블릿 + 기본/1차 확대
    // ==========================================================

    if (width >= 900 && !isLargeText) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(flex: 5, child: TodayScheduleCard()),

          SizedBox(width: 14),

          Expanded(flex: 3, child: SmartQueueCard()),
        ],
      );
    }

    // ==========================================================
    // 130% 이상 또는 좁은 화면
    // ==========================================================

    return const Column(
      children: [TodayScheduleCard(), SizedBox(height: 14), SmartQueueCard()],
    );
  }
}
