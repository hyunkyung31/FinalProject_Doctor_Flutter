import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. AI Result Panel
// ============================================================

class AiResultPanel extends StatefulWidget {
  final List<AiResultUiModel> results;

  final VoidCallback onOpenImaging;

  const AiResultPanel({
    super.key,
    required this.results,
    required this.onOpenImaging,
  });

  @override
  State<AiResultPanel> createState() => _AiResultPanelState();
}

class _AiResultPanelState extends State<AiResultPanel> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();

    if (widget.results.isNotEmpty) {
      _selectedId = widget.results.first.id;
    }
  }

  AiResultUiModel? get _selected {
    for (final result in widget.results) {
      if (result.id == _selectedId) {
        return result;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Row(
      children: [
        // ======================================================
        // Left
        // ======================================================
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AI 결과',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
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
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.appSurfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '실제 AI Result가 아직 생성되지 않아 결과값은 UI 시연 데이터입니다.',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.4,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Divider(height: 1, color: context.appBorder),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.results.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 7);
                    },
                    itemBuilder: (context, index) {
                      final result = widget.results[index];

                      return _ResultListItem(
                        result: result,
                        selected: result.id == _selectedId,
                        onTap: () {
                          setState(() {
                            _selectedId = result.id;
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

        // ======================================================
        // Right
        // ======================================================
        Expanded(
          flex: 6,
          child: selected == null
              ? const _EmptyResult()
              : _ResultDetail(
                  result: selected,
                  onOpenImaging: widget.onOpenImaging,
                ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 2. List Item
// ============================================================

class _ResultListItem extends StatelessWidget {
  final AiResultUiModel result;

  final bool selected;
  final VoidCallback onTap;

  const _ResultListItem({
    required this.result,
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
          color: selected ? context.appSurfaceSoft : context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : context.appBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.patientName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                const _DemoBadge(),

                const SizedBox(width: 5),

                _ResultTypeBadge(type: result.analysisType),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              _resultTypeLabel(result.analysisType),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              result.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: context.appTextSecondary,
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

class _ResultDetail extends StatelessWidget {
  final AiResultUiModel result;

  final VoidCallback onOpenImaging;

  const _ResultDetail({required this.result, required this.onOpenImaging});

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
                    color: context.appSurfaceSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 21,
                    color: context.appBrand,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _resultTypeLabel(result.analysisType),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          const _DemoBadge(),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${result.patientName} · ${result.patientMeta}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: onOpenImaging,
                  icon: const Icon(Icons.image_outlined, size: 15),
                  label: const Text(
                    '영상에서 보기',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.appBorder),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryCard(result: result),

                  const SizedBox(height: 12),

                  if (result.analysisType == 'ANGIO_2D')
                    _buildAngioResult(context),

                  if (result.analysisType == 'CCTA') _buildCctaResult(context),

                  if (result.analysisType == 'LAB') _buildLabResult(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. 2D Angio
  // ============================================================

  Widget _buildAngioResult(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: '협착 탐지',
          icon: Icons.center_focus_strong_outlined,
          child: Column(
            children: [
              for (final detection in result.detections)
                _DetectionRow(detection: detection),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: '병변 정보',
          icon: Icons.monitor_heart_outlined,
          child: Column(
            children: [
              for (final lesion in result.lesions) _LesionRow(lesion: lesion),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'XAI 설명',
          icon: Icons.visibility_outlined,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF071722),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Grad-CAM',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  result.explanation ?? '설명 정보가 없습니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.6,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 5. CCTA
  // ============================================================

  Widget _buildCctaResult(BuildContext context) {
    final cac = result.cacScore;

    return Column(
      children: [
        _SectionCard(
          title: '혈관 Segmentation',
          icon: Icons.hub_outlined,
          child: Column(
            children: [
              for (final item in result.segmentations)
                _SimpleStatusRow(label: item.vessel, value: item.status),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'CAC Score',
          icon: Icons.analytics_outlined,
          child: cac == null
              ? const Text('CAC 결과가 없습니다.')
              : Column(
                  children: [
                    _ValueRow(label: 'LAD', value: cac.lad.toStringAsFixed(0)),
                    _ValueRow(label: 'LCX', value: cac.lcx.toStringAsFixed(0)),
                    _ValueRow(label: 'RCA', value: cac.rca.toStringAsFixed(0)),
                    Divider(color: context.appBorder),
                    _ValueRow(
                      label: 'Total',
                      value: cac.total.toStringAsFixed(0),
                      bold: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 6. LAB
  // ============================================================

  Widget _buildLabResult(BuildContext context) {
    return _SectionCard(
      title: '혈액·임상 AI 결과',
      icon: Icons.biotech_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.summary,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '혈액 AI의 실제 Result Schema는 아직 확인되지 않았습니다. 현재 영역은 통합 판단 화면 구성을 위한 UI Preview입니다.',
            style: TextStyle(
              fontSize: 9.5,
              height: 1.5,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 7. Summary
// ============================================================

class _SummaryCard extends StatelessWidget {
  final AiResultUiModel result;

  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 19,
            color: context.appBrand,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 분석 요약',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.appBrand,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  result.summary,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.appTextPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  result.modelLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: context.appTextSecondary,
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
// STEP 8. Section Card
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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.appBrand),

              const SizedBox(width: 7),

              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
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

// ============================================================
// STEP 9. Rows
// ============================================================

class _DetectionRow extends StatelessWidget {
  final AiDetectionUiModel detection;

  const _DetectionRow({required this.detection});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${detection.vessel} · ${detection.location}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Text(
            '${(detection.confidence * 100).round()}%',
            style: TextStyle(
              fontSize: 10,
              color: context.appTextSecondary,
            ),
          ),

          const SizedBox(width: 8),

          _RiskBadge(level: detection.severity),
        ],
      ),
    );
  }
}

class _LesionRow extends StatelessWidget {
  final AiLesionUiModel lesion;

  const _LesionRow({required this.lesion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '${lesion.vessel} · ${lesion.segment}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Expanded(
            child: LinearProgressIndicator(
              value: lesion.stenosisPercent / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '${lesion.stenosisPercent.round()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),

          const SizedBox(width: 8),

          _RiskBadge(level: lesion.riskLevel),
        ],
      ),
    );
  }
}

class _SimpleStatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  final bool bold;

  const _ValueRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: context.appTextPrimary,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10. Badges
// ============================================================

class _RiskBadge extends StatelessWidget {
  final String level;

  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final isHigh = level == 'HIGH';
    final isModerate = level == 'MODERATE';

    final color = isHigh
        ? AppColors.danger
        : isModerate
        ? AppColors.warning
        : AppColors.success;

    final background = isHigh
        ? AppColors.dangerBackground
        : isModerate
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

class _ResultTypeBadge extends StatelessWidget {
  final String type;

  const _ResultTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: context.appSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBlue,
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

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Center(
        child: Text(
          'AI 결과를 선택해 주세요.',
          style: TextStyle(fontSize: 11.5, color: context.appTextSecondary),
        ),
      ),
    );
  }
}

String _resultTypeLabel(String type) {
  switch (type) {
    case 'ANGIO_2D':
      return '2D 혈관조영 AI 결과';

    case 'CCTA':
      return 'CCTA · 3D AI 결과';

    case 'LAB':
      return '혈액·임상 AI 결과';

    default:
      return type;
  }
}
