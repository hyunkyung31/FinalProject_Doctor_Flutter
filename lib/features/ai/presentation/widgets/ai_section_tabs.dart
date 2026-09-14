import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. AI Section
// ============================================================

enum AiSection { analyses, results, integratedAssessment }

extension AiSectionExtension on AiSection {
  String get label {
    switch (this) {
      case AiSection.analyses:
        return '분석 현황';

      case AiSection.results:
        return 'AI 결과';

      case AiSection.integratedAssessment:
        return '통합 판단';
    }
  }
}

// ============================================================
// STEP 2. Tabs
// ============================================================

class AiSectionTabs extends StatelessWidget {
  final AiSection selectedSection;
  final ValueChanged<AiSection> onChanged;

  const AiSectionTabs({
    super.key,
    required this.selectedSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final section in AiSection.values)
          _AiTabButton(
            label: section.label,
            selected: selectedSection == section,
            onTap: () {
              onChanged(section);
            },
          ),
      ],
    );
  }
}

// ============================================================
// STEP 3. Tab Button
// ============================================================

class _AiTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AiTabButton({
    required this.label,
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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.navy : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
