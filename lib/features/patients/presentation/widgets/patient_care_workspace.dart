import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import 'patient_care_tab.dart';
import 'patient_detail_tabs.dart';
import 'patient_examination_tab.dart';
import 'patient_prescription_tab.dart';

class PatientCareWorkspace extends StatelessWidget {
  final PatientUiModel patient;
  final List<PatientTimelineItem> timelineItems;
  final bool canEditLabResults;
  final VoidCallback onOpenExaminationManagement;
  final Future<List<ExaminationEncounterUiModel>> Function()? encounterLoader;

  const PatientCareWorkspace({
    super.key,
    required this.patient,
    required this.timelineItems,
    required this.canEditLabResults,
    required this.onOpenExaminationManagement,
    this.encounterLoader,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 5,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return PatientCareTab(
              key: ValueKey('patient-care-${patient.patientId}'),
              patient: patient,
              timelineItems: timelineItems,
              encounterLoader: encounterLoader,
              embedded: true,
              onOpenExaminations: () {},
              onOpenPrescriptions: () {},
            );

          case 1:
            return const _DiagnosisPrescriptionHeader();

          case 2:
            return PatientExaminationTab(
              key: ValueKey('patient-examinations-${patient.patientId}'),
              patient: patient,
              timelineItems: timelineItems,
              canEditLabResults: canEditLabResults,
              onOpenExaminationManagement: onOpenExaminationManagement,
              embedded: true,
            );

          case 3:
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Divider(height: 1, color: AppColors.border),
            );

          case 4:
            return PatientPrescriptionTab(
              key: ValueKey('patient-prescriptions-${patient.patientId}'),
              patient: patient,
              embedded: true,
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _DiagnosisPrescriptionHeader extends StatelessWidget {
  const _DiagnosisPrescriptionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 17,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '진단 및 처방',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '검사 오더와 약물 처방을 확인하고 DUR 점검을 진행합니다.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
