import 'package:flutter/material.dart';

import 'patient_detail_tabs.dart';
import 'patient_examination_order_section.dart';

class PatientExaminationTab extends StatelessWidget {
  final PatientUiModel patient;
  final List<PatientTimelineItem> timelineItems;
  final bool canEditLabResults;
  final VoidCallback onOpenExaminationManagement;
  final bool embedded;

  const PatientExaminationTab({
    super.key,
    required this.patient,
    required this.timelineItems,
    required this.canEditLabResults,
    required this.onOpenExaminationManagement,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = PatientExaminationOrderSection(patient: patient);

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: content,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      child: content,
    );
  }
}
