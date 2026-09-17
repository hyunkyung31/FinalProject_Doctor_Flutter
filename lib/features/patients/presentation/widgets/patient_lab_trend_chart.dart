import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../examinations/presentation/examination_ui_models.dart';

class PatientLabTrendChart extends StatefulWidget {
  final List<ExaminationResultUiModel> results;

  const PatientLabTrendChart({super.key, required this.results});

  @override
  State<PatientLabTrendChart> createState() => _PatientLabTrendChartState();
}

class _PatientLabTrendChartState extends State<PatientLabTrendChart> {
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _syncSelectedCode();
  }

  @override
  void didUpdateWidget(covariant PatientLabTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.results, widget.results)) {
      _syncSelectedCode();
    }
  }

  void _syncSelectedCode() {
    final series = _buildTrendSeries(widget.results);

    if (series.isEmpty) {
      _selectedCode = null;
      return;
    }

    final stillExists = series.any((item) => item.code == _selectedCode);

    if (!stillExists) {
      _selectedCode = series.first.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = _buildTrendSeries(widget.results);

    if (series.isEmpty) {
      return _buildEmptyState();
    }

    final selectedSeries = series.firstWhere(
      (item) => item.code == _selectedCode,
      orElse: () => series.first,
    );

    final latestPoint = selectedSeries.points.last;
    final latestMeasurement = latestPoint.measurement;
    final latestValue = latestPoint.value;
    final unit = latestMeasurement.unit?.trim() ?? '';
    final referenceText = _formatReferenceText(
      latestMeasurement.referenceText?.trim() ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '항목별 추이',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '검사 항목의 날짜별 변화를 확인합니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 220,
                child: _buildSelector(context, series, selectedSeries),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildLatestSummary(
            context,
            selectedSeries,
            latestValue,
            unit,
            referenceText,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 270,
            child: _buildLineChart(context, selectedSeries),
          ),
          const SizedBox(height: 12),
          _buildLegend(context, latestMeasurement),
        ],
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    List<_LabTrendSeries> series,
    _LabTrendSeries selectedSeries,
  ) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSeries.code,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: series.map((item) {
            return DropdownMenuItem<String>(
              value: item.code,
              child: Text(
                item.displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedCode = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLatestSummary(
    BuildContext context,
    _LabTrendSeries series,
    double latestValue,
    String unit,
    String referenceText,
  ) {
    final latestMeasurement = series.points.last.measurement;
    final abnormalFlag =
        latestMeasurement.abnormalFlag?.trim().toUpperCase() ?? '';

    final statusColor = _abnormalColor(abnormalFlag);
    final statusLabel = _abnormalLabel(abnormalFlag);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '최근값',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNumber(latestValue),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                          if (unit.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (statusLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정상범위',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  referenceText.isEmpty ? '-' : referenceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '측정 회차',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${series.points.length}회',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, _LabTrendSeries series) {
    final points = series.points;
    final latestMeasurement = points.last.measurement;

    final referenceMin = latestMeasurement.referenceMin;
    final referenceMax = latestMeasurement.referenceMax;

    final rangeValues = points.map((point) => point.value).toList();

    if (referenceMin != null) {
      rangeValues.add(referenceMin);
    }

    if (referenceMax != null) {
      rangeValues.add(referenceMax);
    }

    final rawMin = rangeValues.reduce(math.min);
    final rawMax = rangeValues.reduce(math.max);

    final difference = rawMax - rawMin;
    final padding = difference == 0
        ? (rawMax.abs() * 0.15).clamp(1.0, double.infinity)
        : difference * 0.18;

    final minY = rawMin >= 0
        ? math.max(0.0, rawMin - padding)
        : rawMin - padding;
    final maxY = rawMax + padding;

    final chartColor = Theme.of(context).colorScheme.primary;
    final normalColor = Colors.green.shade600;

    final horizontalLines = <HorizontalLine>[];

    if (referenceMin != null) {
      horizontalLines.add(
        HorizontalLine(
          y: referenceMin,
          color: normalColor.withValues(alpha: 0.65),
          strokeWidth: 1,
          dashArray: const [6, 4],
        ),
      );
    }

    if (referenceMax != null && referenceMax != referenceMin) {
      horizontalLines.add(
        HorizontalLine(
          y: referenceMax,
          color: normalColor.withValues(alpha: 0.65),
          strokeWidth: 1,
          dashArray: const [6, 4],
        ),
      );
    }

    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].value),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Theme.of(context).dividerColor),
            bottom: BorderSide(color: Theme.of(context).dividerColor),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: horizontalLines),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 7,
                  child: Text(
                    _formatAxisNumber(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                final index = value.round();

                if ((value - index).abs() > 0.001 ||
                    index < 0 ||
                    index >= points.length) {
                  return const SizedBox.shrink();
                }

                final point = points[index];

                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatShortDate(point.result.collectedAt),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${point.result.examinationId}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.round();

                if (index < 0 || index >= points.length) {
                  return null;
                }

                final point = points[index];
                final unit = point.measurement.unit?.trim() ?? '';
                final unitText = unit.isEmpty ? '' : ' $unit';

                return LineTooltipItem(
                  '${_formatFullDate(point.result.collectedAt)}\n'
                  '${_formatNumber(point.value)}$unitText\n'
                  '검사 #${point.result.examinationId}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: chartColor,
            barWidth: 2.5,
            isCurved: false,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ExaminationMeasurementUiModel measurement,
  ) {
    final hasReference =
        measurement.referenceMin != null || measurement.referenceMax != null;

    if (!hasReference) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 18, height: 1, color: Colors.green.shade600),
        const SizedBox(width: 6),
        Text(
          '정상범위 기준',
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          const Text(
            '추이를 표시할 수 있는 검사 항목이 없습니다.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '동일 항목이 2회 이상 측정되면 추이를 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

List<_LabTrendSeries> _buildTrendSeries(
  List<ExaminationResultUiModel> results,
) {
  final sortedResults = [...results]
    ..sort((a, b) {
      final dateCompare = a.collectedAt.compareTo(b.collectedAt);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.examinationId.compareTo(b.examinationId);
    });

  final pointsByCode = <String, List<_LabTrendPoint>>{};

  for (final result in sortedResults) {
    final addedCodes = <String>{};

    for (final measurement in result.measurements) {
      final value = measurement.numericValue;

      if (value == null) {
        continue;
      }

      final rawCode = measurement.code.trim();
      final fallbackLabel = measurement.displayLabel.trim();

      if (rawCode.isEmpty && fallbackLabel.isEmpty) {
        continue;
      }

      final code = rawCode.isNotEmpty
          ? rawCode.toUpperCase()
          : fallbackLabel.toUpperCase();

      if (!addedCodes.add(code)) {
        continue;
      }

      pointsByCode.putIfAbsent(code, () => <_LabTrendPoint>[]);

      pointsByCode[code]!.add(
        _LabTrendPoint(result: result, measurement: measurement, value: value),
      );
    }
  }

  final series = <_LabTrendSeries>[];

  for (final entry in pointsByCode.entries) {
    if (entry.value.length < 2) {
      continue;
    }

    final points = entry.value
      ..sort((a, b) {
        final dateCompare = a.result.collectedAt.compareTo(
          b.result.collectedAt,
        );

        if (dateCompare != 0) {
          return dateCompare;
        }

        return a.result.examinationId.compareTo(b.result.examinationId);
      });

    series.add(
      _LabTrendSeries(
        code: entry.key,
        displayLabel: points.last.measurement.displayLabel,
        points: points,
      ),
    );
  }

  series.sort(
    (a, b) =>
        a.displayLabel.toLowerCase().compareTo(b.displayLabel.toLowerCase()),
  );

  return series;
}

class _LabTrendSeries {
  final String code;
  final String displayLabel;
  final List<_LabTrendPoint> points;

  const _LabTrendSeries({
    required this.code,
    required this.displayLabel,
    required this.points,
  });
}

class _LabTrendPoint {
  final ExaminationResultUiModel result;
  final ExaminationMeasurementUiModel measurement;
  final double value;

  const _LabTrendPoint({
    required this.result,
    required this.measurement,
    required this.value,
  });
}

String _abnormalLabel(String flag) {
  switch (flag.trim().toUpperCase()) {
    case 'HIGH':
      return '높음';
    case 'LOW':
      return '낮음';
    case 'NORMAL':
      return '정상';
    default:
      return '';
  }
}

Color _abnormalColor(String flag) {
  switch (flag.trim().toUpperCase()) {
    case 'HIGH':
      return Colors.red.shade600;
    case 'LOW':
      return Colors.blue.shade600;
    case 'NORMAL':
      return Colors.green.shade600;
    default:
      return Colors.grey.shade600;
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatAxisNumber(double value) {
  final absoluteValue = value.abs();

  if (absoluteValue >= 1000) {
    return value.toStringAsFixed(0);
  }

  if (absoluteValue >= 100) {
    return value.toStringAsFixed(0);
  }

  if (absoluteValue >= 10) {
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatReferenceText(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = trimmed.replaceAllMapped(RegExp(r'-?\d+(?:\.\d+)?'), (
    match,
  ) {
    final rawValue = match.group(0) ?? '';
    final number = double.tryParse(rawValue);

    if (number == null) {
      return rawValue;
    }

    return _formatNumber(number);
  });

  return normalized.replaceAll('<=', '≤').replaceAll('>=', '≥');
}

String _formatShortDate(DateTime value) {
  final local = value.toUtc().add(const Duration(hours: 9));

  return '${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}

String _formatFullDate(DateTime value) {
  final local = value.toUtc().add(const Duration(hours: 9));

  return '${local.year}.'
      '${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
