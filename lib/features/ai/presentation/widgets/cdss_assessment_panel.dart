import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. CDSS Assessment Panel
// ============================================================

class CdssAssessmentPanel extends StatefulWidget {
  final List<CdssAssessmentUiModel> assessments;

  final VoidCallback onCreateAssessment;
  final VoidCallback onRecalculate;

  const CdssAssessmentPanel({
    super.key,
    required this.assessments,
    required this.onCreateAssessment,
    required this.onRecalculate,
  });

  @override
  State<CdssAssessmentPanel> createState() => _CdssAssessmentPanelState();
}

class _CdssAssessmentPanelState extends State<CdssAssessmentPanel> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();

    if (widget.assessments.isNotEmpty) {
      _selectedId = widget.assessments.first.id;
    }
  }

  CdssAssessmentUiModel? get _selected {
    for (final assessment in widget.assessments) {
      if (assessment.id == _selectedId) {
        return assessment;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Column(
      children: [
        // ======================================================
        // Demo Notice
        // ======================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.warningBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.warning,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  '현재 CDSS Assessment API 조회 결과는 0건입니다. 아래 통합 판단 결과는 화면 구조 확인을 위한 UI DEMO입니다.',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: Row(
            children: [
              // ==================================================
              // Left
              // ==================================================
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '통합 평가',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            FilledButton.icon(
                              onPressed: widget.onCreateAssessment,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                minimumSize: const Size(100, 36),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 15),
                              label: const Text(
                                '평가 생성',
                                style: TextStyle(fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: AppColors.border),

                      Expanded(
                        child: widget.assessments.isEmpty
                            ? const _EmptyAssessment()
                            : ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: widget.assessments.length,
                                separatorBuilder: (_, _) {
                                  return const SizedBox(height: 7);
                                },
                                itemBuilder: (context, index) {
                                  final assessment = widget.assessments[index];

                                  return _AssessmentListItem(
                                    assessment: assessment,
                                    selected: assessment.id == _selectedId,
                                    onTap: () {
                                      setState(() {
                                        _selectedId = assessment.id;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // Right
              // ==================================================
              Expanded(
                flex: 6,
                child: selected == null
                    ? const _EmptyAssessmentDetail()
                    : _AssessmentDetail(
                        assessment: selected,
                        onRecalculate: widget.onRecalculate,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 2. List Item
// ============================================================

class _AssessmentListItem extends StatelessWidget {
  final CdssAssessmentUiModel assessment;

  final bool selected;
  final VoidCallback onTap;

  const _AssessmentListItem({
    required this.assessment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assessment.patientName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const _DemoBadge(),

                const SizedBox(width: 5),

                _RiskBadge(level: assessment.riskLevel),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Encounter #${assessment.encounterId}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'AI Result ${assessment.aiResultIds.length}건 · ${assessment.rulesetVersion}',
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Detail
// ============================================================

class _AssessmentDetail extends StatelessWidget {
  final CdssAssessmentUiModel assessment;
  final VoidCallback onRecalculate;

  const _AssessmentDetail({
    required this.assessment,
    required this.onRecalculate,
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
          // Header
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    size: 21,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '통합 임상 판단',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(width: 8),

                          const _DemoBadge(),

                          const SizedBox(width: 5),

                          _RiskBadge(level: assessment.riskLevel),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${assessment.patientName} · ${assessment.patientMeta}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: onRecalculate,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('재평가', style: TextStyle(fontSize: 10.5)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ======================================================
          // Content
          // ======================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ==================================================
                  // Risk Summary
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBackground,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 24,
                            color: AppColors.danger,
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '종합 위험도 · ${assessment.riskLevel}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                assessment.summary,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SectionCard(
                    title: '평가 정보',
                    icon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        _ValueRow(
                          label: 'Assessment',
                          value: '#${assessment.id}',
                        ),
                        _ValueRow(
                          label: 'Patient',
                          value: '#${assessment.patientId}',
                        ),
                        _ValueRow(
                          label: 'Encounter',
                          value: '#${assessment.encounterId}',
                        ),
                        _ValueRow(
                          label: 'AI Results',
                          value: assessment.aiResultIds
                              .map((id) => '#$id')
                              .join(', '),
                        ),
                        _ValueRow(
                          label: 'Ruleset',
                          value: assessment.rulesetVersion,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SectionCard(
                    title: '주요 위험요인',
                    icon: Icons.trending_up_rounded,
                    child: Column(
                      children: [
                        for (final component in assessment.riskComponents)
                          _RiskComponentRow(component: component),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SectionCard(
                    title: '판단 근거',
                    icon: Icons.account_tree_outlined,
                    child: Column(
                      children: [
                        for (final source in assessment.sources)
                          _SourceRow(source: source),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SectionCard(
                    title: '권고사항',
                    icon: Icons.fact_check_outlined,
                    child: Column(
                      children: [
                        for (final recommendation in assessment.recommendations)
                          _RecommendationRow(recommendation: recommendation),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 4. Risk Component
// ============================================================

class _RiskComponentRow extends StatelessWidget {
  final CdssRiskComponentUiModel component;

  const _RiskComponentRow({required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  component.description,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            component.value,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 8),

          _RiskBadge(level: component.level),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 5. Source
// ============================================================

class _SourceRow extends StatelessWidget {
  final CdssSourceUiModel source;

  const _SourceRow({required this.source});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              source.sourceType,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  source.description,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
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
// STEP 6. Recommendation
// ============================================================

class _RecommendationRow extends StatelessWidget {
  final CdssRecommendationUiModel recommendation;

  const _RecommendationRow({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: AppColors.navy,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recommendation.title,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    _RiskBadge(level: recommendation.priority),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  recommendation.description,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
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
// STEP 7. Common
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.navy),

              const SizedBox(width: 7),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
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

class _RiskBadge extends StatelessWidget {
  final String level;

  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final high = level == 'HIGH';
    final moderate = level == 'MODERATE';

    final color = high
        ? AppColors.danger
        : moderate
        ? AppColors.warning
        : AppColors.success;

    final background = high
        ? AppColors.dangerBackground
        : moderate
        ? AppColors.warningBackground
        : AppColors.successBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'UI DEMO',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

class _EmptyAssessment extends StatelessWidget {
  const _EmptyAssessment();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          '통합 판단 결과가 없습니다.\nAI 분석 결과가 확정되면 CDSS 평가를 생성할 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyAssessmentDetail extends StatelessWidget {
  const _EmptyAssessmentDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          '통합 판단 항목을 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
