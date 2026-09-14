import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. 환자 UI Model
// 현재는 Mock UI 전용
// 추후 Backend Patient Model 연결 시 교체
// ============================================================

class PatientUiModel {
  final String id;
  final String name;
  final int age;
  final String gender;

  final String department;
  final String doctorName;
  final String careType;

  final bool highRisk;
  final bool aiPending;

  final String currentTask;

  final String phone;
  final String primaryDiagnosis;
  final String riskFactors;
  final String allergy;

  final String latestExam;
  final String latestExamDate;

  final String aiSummary;
  final String nextAppointment;

  const PatientUiModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.department,
    required this.doctorName,
    required this.careType,
    required this.highRisk,
    required this.aiPending,
    required this.currentTask,
    required this.phone,
    required this.primaryDiagnosis,
    required this.riskFactors,
    required this.allergy,
    required this.latestExam,
    required this.latestExamDate,
    required this.aiSummary,
    required this.nextAppointment,
  });
}

// ============================================================
// STEP 2. 환자 상세 Tab
// ============================================================

enum PatientDetailTab { overview, timeline, examinations, imaging, ai }

// ============================================================
// STEP 3. Tab Extension
// ============================================================

extension PatientDetailTabExtension on PatientDetailTab {
  String get label {
    switch (this) {
      case PatientDetailTab.overview:
        return '개요';

      case PatientDetailTab.timeline:
        return '타임라인';

      case PatientDetailTab.examinations:
        return '검사';

      case PatientDetailTab.imaging:
        return '영상';

      case PatientDetailTab.ai:
        return 'AI';
    }
  }

  IconData get icon {
    switch (this) {
      case PatientDetailTab.overview:
        return Icons.dashboard_outlined;

      case PatientDetailTab.timeline:
        return Icons.timeline_rounded;

      case PatientDetailTab.examinations:
        return Icons.science_outlined;

      case PatientDetailTab.imaging:
        return Icons.monitor_heart_outlined;

      case PatientDetailTab.ai:
        return Icons.auto_awesome_outlined;
    }
  }
}

// ============================================================
// STEP 4. Patient Detail Tabs
// ============================================================

class PatientDetailTabs extends StatelessWidget {
  final PatientDetailTab selectedTab;
  final ValueChanged<PatientDetailTab> onChanged;

  const PatientDetailTabs({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final tab in PatientDetailTab.values)
            Expanded(
              child: _PatientTabButton(
                tab: tab,
                selected: tab == selectedTab,
                onTap: () {
                  onChanged(tab);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. 개별 Tab Button
// ============================================================

class _PatientTabButton extends StatelessWidget {
  final PatientDetailTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _PatientTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.navy : Colors.transparent,
                width: selected ? 3 : 0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                size: 16,
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ),

              const SizedBox(width: 6),

              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.navy : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
