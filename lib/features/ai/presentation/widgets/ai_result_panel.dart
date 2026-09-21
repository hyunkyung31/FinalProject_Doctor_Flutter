import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

import '../../../../core/theme/app_theme.dart';
import '../ai_ui_models.dart';

// ============================================================
// STEP 1. AI Result Panel
// ============================================================

class AiResultPanel extends StatefulWidget {
  final List<AiResultUiModel> results;

  final ValueChanged<AiResultUiModel> onResultSelected;
  final VoidCallback onOpenImaging;

  const AiResultPanel({
    super.key,
    required this.results,
    required this.onResultSelected,
    required this.onOpenImaging,
  });

  @override
  State<AiResultPanel> createState() => _AiResultPanelState();
}

class _AiResultPanelState extends State<AiResultPanel> {
  int? _selectedAnalysisId;

  @override
  void initState() {
    super.initState();

    if (widget.results.isNotEmpty) {
      _selectedAnalysisId = widget.results.first.analysisId;
    }
  }

  AiResultUiModel? get _selected {
    for (final result in widget.results) {
      if (result.analysisId == _selectedAnalysisId) {
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
                        selected: result.analysisId == _selectedAnalysisId,
                        onTap: () {
                          setState(() {
                            _selectedAnalysisId = result.analysisId;
                          });

                          debugPrint(
                            '[AI RESULT] 항목 선택: '
                            'analysisId=${result.analysisId}, '
                            'examinationId=${result.examinationId}',
                          );

                          widget.onResultSelected(result);
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

                if (result.isDemo) ...[
                  const _DemoBadge(),
                  const SizedBox(width: 5),
                ],

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
              style: TextStyle(fontSize: 9.5, color: context.appTextSecondary),
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

                          if (result.isDemo) ...[const _DemoBadge()],
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

                  if (result.analysisType == 'CLINICAL' ||
                      result.analysisType == 'LAB')
                    _buildLabResult(context),
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
  // 실제 ANGIO_2D Result JSON 기반
  // ============================================================

  Widget _buildAngioResult(BuildContext context) {
    double? toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      if (value == null) {
        return null;
      }

      return double.tryParse(value.toString());
    }

    int? toInt(dynamic value) {
      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value == null) {
        return null;
      }

      return int.tryParse(value.toString());
    }

    Map<String, dynamic> toMap(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }

      return const {};
    }

    final rawSides = result.resultJson['sides'];

    final sides = rawSides is List
        ? rawSides
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final rawWarnings = result.resultJson['warnings'];

    final warnings = rawWarnings is List
        ? rawWarnings.map((item) => item.toString()).toList()
        : <String>[];

    String sideLabel(String side) {
      switch (side) {
        case 'LEFT':
          return '좌측 관상동맥';

        case 'RIGHT':
          return '우측 관상동맥';

        default:
          return side;
      }
    }

    String predictionLabel(int? prediction) {
      switch (prediction) {
        case 1:
          return '탐지';

        case 0:
          return '미탐지';

        default:
          return '-';
      }
    }

    return Column(
      children: [
        if (sides.isEmpty)
          _SectionCard(
            title: '2D 혈관조영 AI 결과',
            icon: Icons.monitor_heart_outlined,
            child: Text(
              '혈관 측별 AI 분석 결과가 없습니다.',
              style: TextStyle(fontSize: 10.5, color: context.appTextSecondary),
            ),
          ),

        for (final side in sides) ...[
          Builder(
            builder: (context) {
              final sideName = side['side']?.toString() ?? '-';

              final threshold = toDouble(side['threshold']);

              final anyStenosis = toMap(side['any_stenosis']);

              final significantStenosis = toMap(side['significant_stenosis']);

              final features = toMap(side['features']);

              final anyScore = toDouble(anyStenosis['ai_score']);

              final anyPrediction = toInt(anyStenosis['prediction']);

              final significantScore = toDouble(
                significantStenosis['ai_score'],
              );

              final significantPrediction = toInt(
                significantStenosis['prediction'],
              );

              final nFrames = toInt(features['n_frames']);

              final nSeries = toInt(features['n_series']);

              return _SectionCard(
                title: sideLabel(sideName),
                icon: Icons.center_focus_strong_outlined,
                child: Column(
                  children: [
                    _ValueRow(
                      label: '전체 협착 AI score',
                      value: anyScore == null
                          ? '-'
                          : anyScore.toStringAsFixed(3),
                      bold: true,
                    ),

                    _ValueRow(
                      label: '전체 협착 판정',
                      value: predictionLabel(anyPrediction),
                    ),

                    _ValueRow(
                      label: '유의 협착 AI score',
                      value: significantScore == null
                          ? '-'
                          : significantScore.toStringAsFixed(3),
                      bold: true,
                    ),

                    _ValueRow(
                      label: '유의 협착 판정',
                      value: predictionLabel(significantPrediction),
                    ),

                    if (threshold != null)
                      _ValueRow(
                        label: '판정 임계값',
                        value: threshold.toStringAsFixed(3),
                      ),

                    if (nSeries != null)
                      _ValueRow(label: '분석 Series', value: '$nSeries개'),

                    if (nFrames != null)
                      _ValueRow(label: '분석 Frame', value: '$nFrames장'),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),
        ],

        if (warnings.isNotEmpty)
          _SectionCard(
            title: 'AI 결과 안내',
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: context.appBrand,
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            warning,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                      ],
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
          child: result.segmentationDetails.isEmpty
              ? Text(
                  'Segmentation 결과가 없습니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.appTextSecondary,
                  ),
                )
              : Column(
                  children: [
                    for (final item in result.segmentationDetails)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.appSurfaceSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.structureName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),

                            const SizedBox(height: 10),

                            _ValueRow(
                              label: 'Mask File Asset',
                              value: item.maskFileAssetId == null
                                  ? '-'
                                  : '#${item.maskFileAssetId}',
                            ),

                            _ValueRow(
                              label: 'Mesh File Asset',
                              value: item.meshFileAssetId == null
                                  ? '-'
                                  : '#${item.meshFileAssetId}',
                            ),

                            if (item.volumeMm3 != null)
                              _ValueRow(
                                label: 'Volume',
                                value:
                                    '${item.volumeMm3!.toStringAsFixed(1)} mm³',
                              ),

                            if (item.metricsJson['raw_voxels'] != null)
                              _ValueRow(
                                label: 'Raw Voxels',
                                value: '${item.metricsJson['raw_voxels']}',
                              ),

                            if (item.metricsJson['hu130_voxels'] != null)
                              _ValueRow(
                                label: 'HU ≥ 130 Voxels',
                                value: '${item.metricsJson['hu130_voxels']}',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'CAC Score',
          icon: Icons.analytics_outlined,
          child: cac == null
              ? Text(
                  'CAC 결과가 없습니다.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.appTextSecondary,
                  ),
                )
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
  // STEP 6. Clinical
  // ============================================================

  Widget _buildLabResult(BuildContext context) {
    double? toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      if (value == null) {
        return null;
      }

      return double.tryParse(value.toString());
    }

    int? toInt(dynamic value) {
      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value == null) {
        return null;
      }

      return int.tryParse(value.toString());
    }

    final probability = toDouble(result.resultJson['probability']);

    final threshold = toDouble(result.resultJson['threshold']);

    final prediction = toInt(result.resultJson['prediction']);

    final rawWarnings = result.resultJson['warnings'];

    final warnings = rawWarnings is List
        ? rawWarnings.map((item) => item.toString()).toList()
        : <String>[];

    final predictionLabel = switch (prediction) {
      1 => '위험 신호 감지',
      0 => '위험 신호 없음',
      _ => '결과 없음',
    };

    return Column(
      children: [
        _SectionCard(
          title: '혈액·임상 AI 결과',
          icon: Icons.biotech_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueRow(label: '예측 결과', value: predictionLabel, bold: true),

              if (probability != null)
                _ValueRow(
                  label: '위험 확률',
                  value: '${(probability * 100).toStringAsFixed(1)}%',
                ),

              if (threshold != null)
                _ValueRow(
                  label: '판정 임계값',
                  value: '${(threshold * 100).toStringAsFixed(1)}%',
                ),

              if (result.confidence != null)
                _ValueRow(
                  label: 'Confidence',
                  value: '${(result.confidence! * 100).toStringAsFixed(1)}%',
                ),
            ],
          ),
        ),

        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),

          _SectionCard(
            title: '입력 데이터 경고',
            icon: Icons.warning_amber_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Theme.of(context).colorScheme.error,
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            warning,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
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
          Icon(Icons.auto_awesome_outlined, size: 19, color: context.appBrand),

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

    case 'CLINICAL':
    case 'LAB':
      return '혈액·임상 AI 결과';

    default:
      return type;
  }
}
