import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';
import 'patient_overview_tab.dart';
import 'patient_header.dart';
import 'patient_examination_tab.dart';
import 'patient_care_tab.dart';
import 'patient_prescription_tab.dart';
import 'patient_result_tab.dart';

// ============================================================
// STEP 1. Patient Detail Panel
// ============================================================

class PatientDetailPanel extends StatelessWidget {
  final PatientUiModel patient;

  final PatientDetailTab selectedTab;

  final ValueChanged<PatientDetailTab> onTabChanged;

  final List<PatientTimelineItem> timelineItems;

  final bool isTimelineLoading;

  final String? timelineError;

  final bool canEditLabResults;

  final VoidCallback onOpenExaminationManagement;

  const PatientDetailPanel({
    super.key,
    required this.patient,
    required this.selectedTab,
    required this.onTabChanged,
    required this.timelineItems,
    required this.isTimelineLoading,
    required this.timelineError,
    required this.canEditLabResults,
    required this.onOpenExaminationManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ======================================================
          // Patient Header
          // ======================================================
          PatientHeader(patient: patient),

          // ======================================================
          // Tabs
          // ======================================================
          PatientDetailTabs(selectedTab: selectedTab, onChanged: onTabChanged),

          // ======================================================
          // Tab Content
          // ======================================================
          Expanded(child: _buildTabContent(context)),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2. Tab Content
  // ============================================================

  Widget _buildTabContent(BuildContext context) {
    switch (selectedTab) {
      case PatientDetailTab.overview:
        return PatientOverviewTab(
          patient: patient,
          timelineItems: timelineItems,
          isTimelineLoading: isTimelineLoading,
          timelineError: timelineError,
        );

      case PatientDetailTab.care:
        return PatientCareTab(patient: patient);

      case PatientDetailTab.examinations:
        return PatientExaminationTab(
          patient: patient,
          timelineItems: timelineItems,
          canEditLabResults: canEditLabResults,
          onOpenExaminationManagement: onOpenExaminationManagement,
        );

      case PatientDetailTab.prescriptions:
        return PatientPrescriptionTab(patient: patient);

      case PatientDetailTab.aiCdss:
        return _AiTab(patient: patient);

      case PatientDetailTab.results:
        return PatientResultTab(patient: patient);
    }
  }
}

// ============================================================
// STEP 8. AI Tab
// ============================================================

class _AiTab extends StatelessWidget {
  final PatientUiModel patient;

  const _AiTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ======================================================
        // AI Summary
        // ======================================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최근 AI 분석',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      patient.aiSummary,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(
                text: patient.aiPending ? '검토 대기' : '검토 완료',
                color: patient.aiPending
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _RecordCard(
          icon: Icons.analytics_outlined,
          title: '관상동맥 협착 분석',
          subtitle: '2026.09.11 · 협착 위치 / 중증도 / Confidence',
          status: patient.aiPending ? '검토 대기' : '완료',
          statusColor: patient.aiPending
              ? AppColors.warning
              : AppColors.success,
          actionText: 'AI 결과',
          onTap: () {
            _showMessage(context, 'AI 상세 화면은 AI 메뉴에서 연결합니다.');
          },
        ),

        const SizedBox(height: 9),

        _RecordCard(
          icon: Icons.visibility_outlined,
          title: 'XAI 결과',
          subtitle: 'Grad-CAM 및 관심 영역 시각화',
          status: '생성 완료',
          statusColor: AppColors.primaryBlue,
          actionText: '결과 보기',
          onTap: () {
            _showMessage(context, 'XAI 상세 결과 연결 예정');
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 12. Record Card
// ============================================================

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  final String status;
  final Color statusColor;

  final String actionText;

  final VoidCallback onTap;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.onTap,
    this.actionText = '상세보기',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.navy),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          _StatusBadge(text: status, color: statusColor),

          const SizedBox(width: 10),

          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Status Badge
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 14. Message
// ============================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
