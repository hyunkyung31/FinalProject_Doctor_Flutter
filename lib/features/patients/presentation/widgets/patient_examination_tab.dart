import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';
import 'patient_examination_order_section.dart';

class PatientExaminationTab extends StatelessWidget {
  final PatientUiModel patient;
  final List<PatientTimelineItem> timelineItems;
  final bool canEditLabResults;
  final VoidCallback onOpenExaminationManagement;

  const PatientExaminationTab({
    super.key,
    required this.patient,
    required this.timelineItems,
    required this.canEditLabResults,
    required this.onOpenExaminationManagement,
  });

  List<PatientTimelineItem> get _examinationItems {
    final items = timelineItems
        .where((item) => item.eventType.toUpperCase() == 'EXAMINATION')
        .toList();

    items.sort((a, b) {
      final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final examinationItems = _examinationItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientExaminationOrderSection(patient: patient),

          const SizedBox(height: 18),

          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 18),
          _SectionHeader(
            icon: Icons.history_rounded,
            title: '검사 이력',
            action: OutlinedButton.icon(
              onPressed: onOpenExaminationManagement,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text(
                '검사 관리에서 열기',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ),
            trailing: examinationItems.isEmpty
                ? null
                : '${examinationItems.length}건',
          ),
          const SizedBox(height: 6),
          const Text(
            '환자에게 처방되거나 수행된 검사 이력을 확인합니다.',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (examinationItems.isEmpty)
            const _EmptySection(text: '등록된 검사 이력이 없습니다.')
          else
            _ExaminationSessionSection(items: examinationItems),
        ],
      ),
    );
  }
}

class _ExaminationSessionSection extends StatelessWidget {
  final List<PatientTimelineItem> items;

  const _ExaminationSessionSection({required this.items});

  String _dateKey(DateTime? value) {
    if (value == null) {
      return 'unknown';
    }

    final local = value.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(String key) {
    if (key == 'unknown') {
      return '날짜 정보 없음';
    }

    return key.replaceAll('-', '.');
  }

  Map<String, List<PatientTimelineItem>> _groupByDate() {
    final groups = <String, List<PatientTimelineItem>>{};

    for (final item in items) {
      final key = _dateKey(item.occurredAt);

      groups.putIfAbsent(key, () => <PatientTimelineItem>[]);

      groups[key]!.add(item);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < groups.entries.length; index++) ...[
          _ExaminationDateGroup(
            date: _displayDate(groups.entries.elementAt(index).key),
            items: groups.entries.elementAt(index).value,
            showCount: groups.length > 1,
          ),
          if (index != groups.entries.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ExaminationDateGroup extends StatelessWidget {
  final String date;
  final List<PatientTimelineItem> items;
  final bool showCount;

  const _ExaminationDateGroup({
    required this.date,
    required this.items,
    required this.showCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 7),
              Text(
                '${items.length}건',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _ExaminationTile(item: items[index]),
                if (index != items.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExaminationTile extends StatelessWidget {
  final PatientTimelineItem item;

  const _ExaminationTile({required this.item});

  String get _code {
    return item.data['examination_type_code']
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
  }

  String _displayName() {
    switch (_code) {
      case 'BLOOD':
      case 'CARDIAC_LAB_PANEL':
        return '혈액검사';

      case 'ANGIO_2D':
      case 'ANGIOGRAPHY':
        return '관상동맥조영술';

      case 'CCTA':
      case 'CCTA_3D':
        return '관상동맥 CT 검사';

      default:
        final title = item.title.trim();

        if (title.isNotEmpty) {
          return title;
        }

        return '검사';
    }
  }

  IconData _icon() {
    switch (_code) {
      case 'BLOOD':
      case 'CARDIAC_LAB_PANEL':
        return Icons.science_outlined;

      case 'ANGIO_2D':
      case 'ANGIOGRAPHY':
        return Icons.video_library_outlined;

      case 'CCTA':
      case 'CCTA_3D':
        return Icons.monitor_heart_outlined;

      default:
        return Icons.medical_services_outlined;
    }
  }

  Color _color() {
    switch (_code) {
      case 'BLOOD':
      case 'CARDIAC_LAB_PANEL':
        return AppColors.success;

      case 'ANGIO_2D':
      case 'ANGIOGRAPHY':
        return AppColors.secondaryBlue;

      case 'CCTA':
      case 'CCTA_3D':
        return AppColors.primaryBlue;

      default:
        return AppColors.navy;
    }
  }

  String _metaText() {
    final parts = <String>[];

    void addPart(String? value) {
      final text = value?.trim() ?? '';

      if (text.isEmpty) {
        return;
      }

      final normalized = text.toLowerCase();

      const placeholders = {'string', 'null', 'none', 'n/a', '-'};

      if (placeholders.contains(normalized)) {
        return;
      }

      final alreadyExists = parts.any(
        (part) => part.toLowerCase() == normalized,
      );

      if (!alreadyExists) {
        parts.add(text);
      }
    }

    addPart(item.summary);
    addPart(item.data['modality']?.toString());

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final meta = _metaText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(_icon(), size: 15, color: color),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              _displayName(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              meta.isEmpty ? '-' : meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  final String? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.action,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.navy),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (action != null) ...[action!, const SizedBox(width: 10)],
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
      ),
    );
  }
}
