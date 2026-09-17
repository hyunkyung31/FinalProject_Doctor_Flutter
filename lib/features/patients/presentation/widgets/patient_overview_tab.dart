import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'patient_detail_tabs.dart';

// ============================================================
// STEP 1. Patient Overview Tab
// 환자 정보 + 연결 데이터 + 최근 진료기록
// Card Dashboard가 아닌 EMR / Medical Chart 형태
// ============================================================

class PatientOverviewTab extends StatelessWidget {
  final PatientUiModel patient;
  final List<PatientTimelineItem> timelineItems;
  final bool isTimelineLoading;
  final String? timelineError;

  const PatientOverviewTab({
    super.key,
    required this.patient,
    required this.timelineItems,
    required this.isTimelineLoading,
    required this.timelineError,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // STEP 2. 연결 데이터
          // ======================================================
          _MedicalDataSection(
            labCount: patient.labMeasurementCount,
            ctCount: patient.ctStudyCount,
            angiographyCount: patient.angiographySequenceCount,
          ),

          const SizedBox(height: 18),

          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 18),

          // ======================================================
          // STEP 3. 최근 진료기록
          // ======================================================
          _RecentTimelineSection(
            items: timelineItems,
            isLoading: isTimelineLoading,
            error: timelineError,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Medical Data Section
// ============================================================

class _MedicalDataSection extends StatelessWidget {
  final int labCount;
  final int ctCount;
  final int angiographyCount;

  const _MedicalDataSection({
    required this.labCount,
    required this.ctCount,
    required this.angiographyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.folder_shared_outlined,
          title: '연결 데이터',
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            // ==================================================
            // 넓은 화면
            // ==================================================

            if (constraints.maxWidth >= 620) {
              return Row(
                children: [
                  Expanded(
                    child: _MedicalMetric(
                      icon: Icons.science_outlined,
                      label: '검사',
                      value: '$labCount',
                      unit: '개',
                      color: AppColors.navy,
                    ),
                  ),

                  const _VerticalSectionDivider(),

                  Expanded(
                    child: _MedicalMetric(
                      icon: Icons.monitor_heart_outlined,
                      label: 'CT',
                      value: '$ctCount',
                      unit: 'Study',
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const _VerticalSectionDivider(),

                  Expanded(
                    child: _MedicalMetric(
                      icon: Icons.video_library_outlined,
                      label: '혈관조영',
                      value: '$angiographyCount',
                      unit: 'Sequence',
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ],
              );
            }

            // ==================================================
            // 좁은 화면
            // ==================================================

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _MedicalMetric(
                    icon: Icons.science_outlined,
                    label: '검사',
                    value: '$labCount',
                    unit: '개',
                    color: AppColors.navy,
                  ),
                ),

                SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _MedicalMetric(
                    icon: Icons.monitor_heart_outlined,
                    label: 'CT',
                    value: '$ctCount',
                    unit: 'Study',
                    color: AppColors.primaryBlue,
                  ),
                ),

                SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _MedicalMetric(
                    icon: Icons.video_library_outlined,
                    label: '혈관조영',
                    value: '$angiographyCount',
                    unit: 'Sequence',
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// STEP 9. Medical Metric
// 개별 Card 대신 한 줄 정보 강조
// ============================================================

class _MedicalMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MedicalMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// STEP 10. Recent Timeline Section
// 날짜별 Accordion + 임상 유형별 그룹
// 최신 날짜는 기본 펼침
// ============================================================

class _RecentTimelineSection extends StatefulWidget {
  final List<PatientTimelineItem> items;
  final bool isLoading;
  final String? error;

  const _RecentTimelineSection({
    required this.items,
    required this.isLoading,
    required this.error,
  });

  @override
  State<_RecentTimelineSection> createState() => _RecentTimelineSectionState();
}

class _RecentTimelineSectionState extends State<_RecentTimelineSection> {
  final Set<String> _expandedDates = {};

  // ==========================================================
  // 초기 최신 날짜 펼침
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final groups = _groupByDate();

    if (groups.isNotEmpty) {
      _expandedDates.add(groups.keys.first);
    }
  }

  @override
  void didUpdateWidget(covariant _RecentTimelineSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final groups = _groupByDate();

    if (groups.isEmpty) {
      _expandedDates.clear();
      return;
    }

    _expandedDates.removeWhere((date) => !groups.containsKey(date));

    if (_expandedDates.isEmpty) {
      _expandedDates.add(groups.keys.first);
    }
  }

  // ==========================================================
  // 날짜 Key
  // ==========================================================

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

  // ==========================================================
  // 날짜 표시
  // ==========================================================

  String _displayDate(String key) {
    if (key == 'unknown') {
      return '날짜 미상';
    }

    return key.replaceAll('-', '.');
  }

  // ==========================================================
  // Timeline 날짜별 그룹
  // 최신 날짜 우선
  // ==========================================================

  Map<String, List<PatientTimelineItem>> _groupByDate() {
    final sortedItems = [...widget.items];

    sortedItems.sort((a, b) {
      final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    final groups = <String, List<PatientTimelineItem>>{};

    for (final item in sortedItems) {
      final key = _dateKey(item.occurredAt);

      groups.putIfAbsent(key, () => <PatientTimelineItem>[]);

      groups[key]!.add(item);
    }

    return groups;
  }

  // ==========================================================
  // 날짜별 요약
  // ex) 진료 1 · 검사 3 · AI 1
  // ==========================================================

  String _dateSummary(List<PatientTimelineItem> items) {
    var encounterCount = 0;
    var examinationCount = 0;
    var aiCount = 0;
    var reportCount = 0;

    for (final item in items) {
      switch (item.eventType.toUpperCase()) {
        case 'ENCOUNTER':
          encounterCount++;
          break;

        case 'EXAMINATION':
          examinationCount++;
          break;

        case 'AI_ANALYSIS':
          aiCount++;
          break;

        case 'REPORT':
          reportCount++;
          break;
      }
    }

    final parts = <String>[];

    if (encounterCount > 0) {
      parts.add('진료 $encounterCount건');
    }

    if (examinationCount > 0) {
      parts.add('검사 $examinationCount건');
    }

    if (aiCount > 0) {
      parts.add('AI $aiCount건');
    }

    if (reportCount > 0) {
      parts.add('보고서 $reportCount건');
    }

    if (parts.isEmpty) {
      return '${items.length}건';
    }

    return parts.join(' · ');
  }

  // ==========================================================
  // Status
  // 완료 / 성공은 정상 상태이므로 개요에서 숨김
  // ==========================================================

  bool _shouldShowStatus(String status) {
    final normalized = status.toUpperCase();

    return normalized.isNotEmpty &&
        normalized != 'COMPLETED' &&
        normalized != 'SUCCEEDED';
  }

  String _statusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '대기';

      case 'RUNNING':
        return '진행 중';

      case 'FAILED':
        return '실패';

      case 'CANCELED':
      case 'CANCELLED':
        return '취소';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'RUNNING':
      case 'FAILED':
        return AppColors.warning;

      case 'CANCELED':
      case 'CANCELLED':
        return AppColors.textSecondary;

      default:
        return AppColors.primaryBlue;
    }
  }

  // ==========================================================
  // 진료 Meta
  // ==========================================================

  String _encounterMeta(PatientTimelineItem item) {
    final parts = <String>[];

    final doctorName = item.data['doctor_name']?.toString().trim();

    if (doctorName != null && doctorName.isNotEmpty) {
      parts.add('$doctorName 의사');
    }

    if (item.summary.trim().isNotEmpty) {
      parts.add(item.summary.trim());
    }

    return parts.join(' · ');
  }

  // ==========================================================
  // 검사 Meta
  // ==========================================================

  String _examinationMeta(PatientTimelineItem item) {
    final parts = <String>[];

    if (item.summary.trim().isNotEmpty) {
      parts.add(item.summary.trim());
    }

    final modality = item.data['modality']?.toString().trim();

    if (modality != null && modality.isNotEmpty && !parts.contains(modality)) {
      parts.add(modality);
    }

    return parts.join(' · ');
  }

  // ==========================================================
  // 일반 Meta
  // ==========================================================

  String _defaultMeta(PatientTimelineItem item) {
    return item.summary.trim();
  }

  // ==========================================================
  // 날짜 안의 임상 기록
  // ==========================================================

  Widget _buildDateContent(List<PatientTimelineItem> items) {
    final encounters = items
        .where((item) => item.eventType.toUpperCase() == 'ENCOUNTER')
        .toList();

    final examinations = items
        .where((item) => item.eventType.toUpperCase() == 'EXAMINATION')
        .toList();

    final aiAnalyses = items
        .where((item) => item.eventType.toUpperCase() == 'AI_ANALYSIS')
        .toList();

    final reports = items
        .where((item) => item.eventType.toUpperCase() == 'REPORT')
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // 진료
          // ====================================================
          if (encounters.isNotEmpty)
            _ClinicalRecordGroup(
              icon: Icons.local_hospital_outlined,
              title: '진료',
              color: AppColors.primaryBlue,
              children: [
                for (final item in encounters)
                  _ClinicalRecordRow(
                    title: item.title,
                    subtitle: _encounterMeta(item),
                    statusText: _shouldShowStatus(item.status)
                        ? _statusText(item.status)
                        : null,
                    statusColor: _statusColor(item.status),
                  ),
              ],
            ),

          if (encounters.isNotEmpty && examinations.isNotEmpty)
            const SizedBox(height: 16),

          // ====================================================
          // 검사
          // ====================================================
          if (examinations.isNotEmpty)
            _ClinicalRecordGroup(
              icon: Icons.science_outlined,
              title: '검사',
              color: AppColors.success,
              children: [
                for (final item in examinations)
                  _ClinicalRecordRow(
                    title: item.title,
                    subtitle: _examinationMeta(item),
                    statusText: _shouldShowStatus(item.status)
                        ? _statusText(item.status)
                        : null,
                    statusColor: _statusColor(item.status),
                  ),
              ],
            ),

          if ((encounters.isNotEmpty || examinations.isNotEmpty) &&
              aiAnalyses.isNotEmpty)
            const SizedBox(height: 16),

          // ====================================================
          // AI
          // ====================================================
          if (aiAnalyses.isNotEmpty)
            _ClinicalRecordGroup(
              icon: Icons.auto_awesome_outlined,
              title: 'AI 분석',
              color: AppColors.warning,
              children: [
                for (final item in aiAnalyses)
                  _ClinicalRecordRow(
                    title: item.title,
                    subtitle: _defaultMeta(item),
                    statusText: _shouldShowStatus(item.status)
                        ? _statusText(item.status)
                        : null,
                    statusColor: _statusColor(item.status),
                  ),
              ],
            ),

          if ((encounters.isNotEmpty ||
                  examinations.isNotEmpty ||
                  aiAnalyses.isNotEmpty) &&
              reports.isNotEmpty)
            const SizedBox(height: 16),

          // ====================================================
          // 보고서
          // ====================================================
          if (reports.isNotEmpty)
            _ClinicalRecordGroup(
              icon: Icons.description_outlined,
              title: '보고서',
              color: AppColors.secondaryBlue,
              children: [
                for (final item in reports)
                  _ClinicalRecordRow(
                    title: item.title,
                    subtitle: _defaultMeta(item),
                    statusText: _shouldShowStatus(item.status)
                        ? _statusText(item.status)
                        : null,
                    statusColor: _statusColor(item.status),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupByDate();

    // 개요에서는 최근 3개 날짜까지만 표시
    final visibleGroups = groupedItems.entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // Header
        // ======================================================
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                icon: Icons.history_rounded,
                title: '최근 진료기록',
              ),
            ),

            if (!widget.isLoading &&
                widget.error == null &&
                widget.items.isNotEmpty)
              Text(
                '전체 ${widget.items.length}건',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ======================================================
        // Loading
        // ======================================================
        if (widget.isLoading)
          const SizedBox(
            height: 90,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        // ======================================================
        // Error
        // ======================================================
        else if (widget.error != null)
          const _OverviewMessage(text: '진료기록을 불러오지 못했습니다.')
        // ======================================================
        // Empty
        // ======================================================
        else if (widget.items.isEmpty)
          const _OverviewMessage(text: '등록된 진료기록이 없습니다.')
        // ======================================================
        // Date Accordion
        // ======================================================
        else
          Column(
            children: [
              for (var index = 0; index < visibleGroups.length; index++) ...[
                _TimelineDateGroup(
                  date: _displayDate(visibleGroups[index].key),
                  summary: _dateSummary(visibleGroups[index].value),
                  expanded: _expandedDates.contains(visibleGroups[index].key),
                  onTap: () {
                    final key = visibleGroups[index].key;

                    setState(() {
                      if (_expandedDates.contains(key)) {
                        _expandedDates.remove(key);
                      } else {
                        _expandedDates.add(key);
                      }
                    });
                  },
                  child: _buildDateContent(visibleGroups[index].value),
                ),

                if (index != visibleGroups.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],

              if (groupedItems.length > visibleGroups.length) ...[
                const SizedBox(height: 12),

                Text(
                  '최근 ${visibleGroups.length}개 날짜의 기록을 표시하고 있습니다.',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// ============================================================
// STEP 11. 날짜별 Accordion Header
// ============================================================

class _TimelineDateGroup extends StatelessWidget {
  final String date;
  final String summary;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _TimelineDateGroup({
    required this.date,
    required this.summary,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        if (expanded) child,
      ],
    );
  }
}

// ============================================================
// STEP 12. 진료 / 검사 / AI / 보고서 Group
// ============================================================

class _ClinicalRecordGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _ClinicalRecordGroup({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: color),
            ),

            const SizedBox(width: 7),

            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],

                if (index != children.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 13. Clinical Record Row
// 정상 완료 상태는 표시하지 않고
// 예외 / 진행 상태만 Badge 표시
// ============================================================

class _ClinicalRecordRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? statusText;
  final Color statusColor;

  const _ClinicalRecordRow({
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? '제목 없음' : title.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    subtitle.trim(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (statusText != null) ...[
            const SizedBox(width: 10),

            _SmallBadge(text: statusText!, color: statusColor),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// STEP 13. Shared Section Header
// ============================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

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
      ],
    );
  }
}

// ============================================================
// STEP 14. Vertical Divider
// ============================================================

class _VerticalSectionDivider extends StatelessWidget {
  const _VerticalSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }
}

// ============================================================
// STEP 15. Small Badge
// ============================================================

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 16. Overview Message
// ============================================================

class _OverviewMessage extends StatelessWidget {
  final String text;

  const _OverviewMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
      ),
    );
  }
}
