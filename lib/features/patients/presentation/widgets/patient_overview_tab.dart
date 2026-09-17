import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/patient_care_service.dart';
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
          _OverviewPatientInfoSection(patient: patient),

          const SizedBox(height: 18),

          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 18),

          _OverviewClinicalSummarySection(patient: patient),

          const SizedBox(height: 18),

          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 18),

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

class _OverviewPatientInfoSection extends StatelessWidget {
  final PatientUiModel patient;

  const _OverviewPatientInfoSection({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.person_outline_rounded,
          title: '환자 기본정보',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 720 ? 3 : 2;
              final spacing = 12.0;
              final totalSpacing = spacing * (columnCount - 1);
              final itemWidth =
                  (constraints.maxWidth - totalSpacing) / columnCount;

              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '환자번호',
                      value: _overviewValue(patient.medicalRecordNo),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '성별 / 나이',
                      value:
                          '${_overviewValue(patient.gender)} / ${patient.age}세',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '생년월일',
                      value: _formatOverviewDate(patient.birthDate),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '연락처',
                      value: _overviewValue(patient.phone),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '진료과',
                      value: _overviewValue(patient.department),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewInfoItem(
                      label: '담당 의료진',
                      value: _overviewValue(patient.doctorName),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OverviewClinicalSummarySection extends StatefulWidget {
  final PatientUiModel patient;

  const _OverviewClinicalSummarySection({required this.patient});

  @override
  State<_OverviewClinicalSummarySection> createState() =>
      _OverviewClinicalSummarySectionState();
}

class _OverviewClinicalSummarySectionState
    extends State<_OverviewClinicalSummarySection> {
  List<PatientMedicalHistory> _medicalHistories = [];
  bool _isLoadingMedicalHistories = true;
  bool _medicalHistoryLoadFailed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicalHistories();
    });
  }

  @override
  void didUpdateWidget(covariant _OverviewClinicalSummarySection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _loadMedicalHistories();
    }
  }

  Future<void> _loadMedicalHistories() async {
    final requestedPatientId = widget.patient.patientId;

    setState(() {
      _isLoadingMedicalHistories = true;
      _medicalHistoryLoadFailed = false;
    });

    try {
      final auth = context.read<AuthProvider>();

      final careService = PatientCareService(
        apiClient: auth.authService.apiClient,
      );

      final histories = await careService.fetchMedicalHistories(
        requestedPatientId,
      );

      if (!mounted || requestedPatientId != widget.patient.patientId) {
        return;
      }

      histories.sort((a, b) {
        final aActive = a.status.toUpperCase() == 'ACTIVE';
        final bActive = b.status.toUpperCase() == 'ACTIVE';

        if (aActive != bActive) {
          return aActive ? -1 : 1;
        }

        final aDate = a.onsetDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.onsetDate ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      setState(() {
        _medicalHistories = histories;
        _isLoadingMedicalHistories = false;
      });
    } catch (error) {
      debugPrint('[PatientOverviewTab] 과거력 조회 실패: $error');

      if (!mounted || requestedPatientId != widget.patient.patientId) {
        return;
      }

      setState(() {
        _medicalHistories = [];
        _isLoadingMedicalHistories = false;
        _medicalHistoryLoadFailed = true;
      });
    }
  }

  String _medicalHistorySummary() {
    if (_isLoadingMedicalHistories) {
      return '불러오는 중';
    }

    if (_medicalHistoryLoadFailed) {
      return '과거력 정보를 불러오지 못했습니다.';
    }

    if (_medicalHistories.isEmpty) {
      return '등록된 과거력 없음';
    }

    return _medicalHistories
        .take(5)
        .map((history) {
          final name = history.conditionName.trim().isEmpty
              ? history.conditionCode
              : history.conditionName;

          if (history.onsetDate == null) {
            return name;
          }

          final date = history.onsetDate!;
          final year = date.year.toString();
          final month = date.month.toString().padLeft(2, '0');
          final day = date.day.toString().padLeft(2, '0');

          return '$name ($year.$month.$day~)';
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.monitor_heart_outlined,
          title: '임상 요약',
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _OverviewClinicalRow(
                label: '주요 진단',
                value: _overviewValue(
                  widget.patient.primaryDiagnosis,
                  fallback: '등록된 주요 진단 없음',
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              _OverviewClinicalRow(
                label: '과거력',
                value: _medicalHistorySummary(),
              ),

              const Divider(height: 1, color: AppColors.border),

              _OverviewClinicalRow(
                label: '위험 요인',
                value: _overviewValue(
                  widget.patient.riskFactors,
                  fallback: '등록된 위험 요인 없음',
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              _OverviewClinicalRow(
                label: '알레르기',
                value: _overviewValue(
                  widget.patient.allergy,
                  fallback: '등록된 알레르기 없음',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OverviewClinicalRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewClinicalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _overviewValue(String value, {String fallback = '-'}) {
  final text = value.trim();

  if (text.isEmpty) {
    return fallback;
  }

  return text;
}

String _formatOverviewDate(String value) {
  final parsed = DateTime.tryParse(value);

  if (parsed == null) {
    return _overviewValue(value);
  }

  final year = parsed.year.toString().padLeft(4, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');

  return '$year.$month.$day';
}

// ============================================================
// Recent Timeline Section
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
