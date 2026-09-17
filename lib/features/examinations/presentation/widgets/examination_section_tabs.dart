import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// 검사 관리 화면 Section
// ============================================================

enum ExaminationSection { orders, results }

extension ExaminationSectionExtension on ExaminationSection {
  String get label {
    switch (this) {
      case ExaminationSection.orders:
        return '검사 관리';

      case ExaminationSection.results:
        return '결과 확인';
    }
  }
}

// ============================================================
// Section Tabs
// ============================================================

class ExaminationSectionTabs extends StatelessWidget {
  final ExaminationSection selectedSection;
  final ValueChanged<ExaminationSection> onChanged;

  const ExaminationSectionTabs({
    super.key,
    required this.selectedSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final section in ExaminationSection.values)
          _SectionTabButton(
            label: section.label,
            selected: section == selectedSection,
            onTap: () {
              onChanged(section);
            },
          ),
      ],
    );
  }
}

// ============================================================
// Tab Button
// ============================================================

class _SectionTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SectionTabButton({
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
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.navy : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
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
