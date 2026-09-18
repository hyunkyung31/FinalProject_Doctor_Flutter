import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import 'patient_detail_tabs.dart';
import 'patient_overview_tab.dart';
import 'patient_header.dart';
import 'patient_examination_tab.dart';
// import 'patient_care_tab.dart';
import 'patient_prescription_tab.dart';
import 'patient_result_tab.dart';
import 'patient_care_workspace.dart';

// ============================================================
// STEP 1. Patient Detail Panel
// ============================================================

class PatientDetailPanel extends StatefulWidget {
  final PatientUiModel patient;

  final PatientDetailTab selectedTab;

  final ValueChanged<PatientDetailTab> onTabChanged;

  final List<PatientTimelineItem> timelineItems;

  final bool isTimelineLoading;

  final String? timelineError;

  final bool canEditLabResults;

  final VoidCallback onOpenExaminationManagement;

  final Future<List<ExaminationEncounterUiModel>> Function()? encounterLoader;

  const PatientDetailPanel({
    super.key,
    required this.patient,
    required this.selectedTab,
    required this.onTabChanged,
    required this.timelineItems,
    required this.isTimelineLoading,
    required this.timelineError,
    required this.canEditLabResults,
    this.encounterLoader,
    required this.onOpenExaminationManagement,
  });

  @override
  State<PatientDetailPanel> createState() => _PatientDetailPanelState();
}

class _PatientDetailPanelState extends State<PatientDetailPanel> {
  late Set<PatientDetailTab> _visitedTabs;

  @override
  void initState() {
    super.initState();

    _visitedTabs = {PatientDetailTab.overview, widget.selectedTab};
  }

  @override
  void didUpdateWidget(covariant PatientDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _visitedTabs = {PatientDetailTab.overview, widget.selectedTab};
      return;
    }

    _visitedTabs.add(widget.selectedTab);
  }

  int get _selectedIndex {
    switch (widget.selectedTab) {
      case PatientDetailTab.overview:
        return 0;

      case PatientDetailTab.care:
        return 1;

      case PatientDetailTab.examinations:
        return 2;

      case PatientDetailTab.prescriptions:
        return 3;

      case PatientDetailTab.aiCdss:
        return 4;

      case PatientDetailTab.results:
        return 5;
    }
  }

  bool _hasVisited(PatientDetailTab tab) {
    return _visitedTabs.contains(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          PatientHeader(patient: widget.patient),

          PatientDetailTabs(
            selectedTab: widget.selectedTab,
            onChanged: widget.onTabChanged,
          ),

          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverviewTab(),
                _buildCareTab(),
                _buildExaminationTab(),
                _buildPrescriptionTab(),
                _buildAiTab(),
                _buildResultTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (!_hasVisited(PatientDetailTab.overview)) {
      return const SizedBox.shrink();
    }

    return PatientOverviewTab(
      key: ValueKey('patient-overview-${widget.patient.patientId}'),
      patient: widget.patient,
      timelineItems: widget.timelineItems,
      isTimelineLoading: widget.isTimelineLoading,
      timelineError: widget.timelineError,
    );
  }

  Widget _buildCareTab() {
    if (!_hasVisited(PatientDetailTab.care)) {
      return const SizedBox.shrink();
    }

    return PatientCareWorkspace(
      key: ValueKey('patient-care-workspace-${widget.patient.patientId}'),
      patient: widget.patient,
      timelineItems: widget.timelineItems,
      canEditLabResults: widget.canEditLabResults,
      encounterLoader: widget.encounterLoader,
      onOpenExaminationManagement: widget.onOpenExaminationManagement,
    );
  }

  Widget _buildExaminationTab() {
    if (!_hasVisited(PatientDetailTab.examinations)) {
      return const SizedBox.shrink();
    }

    return PatientExaminationTab(
      key: ValueKey('patient-examinations-${widget.patient.patientId}'),
      patient: widget.patient,
      timelineItems: widget.timelineItems,
      canEditLabResults: widget.canEditLabResults,
      onOpenExaminationManagement: widget.onOpenExaminationManagement,
    );
  }

  Widget _buildPrescriptionTab() {
    if (!_hasVisited(PatientDetailTab.prescriptions)) {
      return const SizedBox.shrink();
    }

    return PatientPrescriptionTab(
      key: ValueKey('patient-prescriptions-${widget.patient.patientId}'),
      patient: widget.patient,
    );
  }

  Widget _buildAiTab() {
    if (!_hasVisited(PatientDetailTab.aiCdss)) {
      return const SizedBox.shrink();
    }

    return _AiTab(
      key: ValueKey('patient-ai-${widget.patient.patientId}'),
      patient: widget.patient,
    );
  }

  Widget _buildResultTab() {
    if (!_hasVisited(PatientDetailTab.results)) {
      return const SizedBox.shrink();
    }

    return PatientResultTab(
      key: ValueKey('patient-results-${widget.patient.patientId}'),
      patient: widget.patient,
      timelineItems: widget.timelineItems,
    );
  }
}

// ============================================================
// STEP 8. AI Tab
// ============================================================

class _AiTab extends StatelessWidget {
  final PatientUiModel patient;

  const _AiTab({super.key, required this.patient});

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
            color: context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: context.appPrimary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 AI 분석',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.appTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      patient.aiSummary,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
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
          statusColor: context.appPrimary,
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.appSurfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: context.appBrand),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appTextSecondary,
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
              foregroundColor: context.appPrimary,
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
