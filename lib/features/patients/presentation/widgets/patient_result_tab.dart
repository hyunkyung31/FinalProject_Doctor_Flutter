import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';
import '../../../examinations/data/services/patient_lab_result_service.dart';
import 'patient_detail_tabs.dart';
import 'patient_lab_trend_chart.dart';

class PatientResultTab extends StatefulWidget {
  final PatientUiModel patient;

  const PatientResultTab({super.key, required this.patient});

  @override
  State<PatientResultTab> createState() => _PatientResultTabState();
}

class _PatientResultTabState extends State<PatientResultTab> {
  List<ExaminationResultUiModel> _results = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResults();
    });
  }

  @override
  void didUpdateWidget(covariant PatientResultTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patient.patientId != widget.patient.patientId) {
      _loadResults();
    }
  }

  Future<void> _loadResults() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      final examinationService = ExaminationService(
        apiClient: auth.authService.apiClient,
      );

      final resultService = PatientLabResultService(
        examinationService: examinationService,
      );

      final results = await resultService.fetchPatientLabResults(
        patientId: widget.patient.patientId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      debugPrint(
        '[PatientResultTab] 혈액검사 결과 조회 실패: '
        'patientId=${widget.patient.patientId}, error=$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = [];
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: AppColors.danger,
            ),
            const SizedBox(height: 10),
            const Text(
              '혈액검사 결과를 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.science_outlined,
              size: 30,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 10),
            const Text(
              '확인할 수 있는 혈액검사 결과가 없습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('새로고침'),
            ),
          ],
        ),
      );
    }

    final latestResult = _results.first;

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '혈액검사 결과',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '확정된 검사 수치와 검사 이력을 확인합니다.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadResults,
                tooltip: '새로고침',
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _LatestResultSummary(result: latestResult),

          const SizedBox(height: 16),

          PatientLabTrendChart(results: _results),

          const SizedBox(height: 20),

          const Text(
            '최근 혈액검사 수치',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          _MeasurementGrid(measurements: latestResult.measurements),

          const SizedBox(height: 20),

          const Text(
            '검사 이력',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          ..._results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ResultHistoryCard(result: result),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestResultSummary extends StatelessWidget {
  final ExaminationResultUiModel result;

  const _LatestResultSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final abnormalCount = result.measurements
        .where((measurement) => measurement.isAbnormal)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.biotech_outlined,
              size: 21,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최근 혈액검사',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(result.collectedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '총 ${result.measurements.length}개 항목 · 이상 수치 $abnormalCount개',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          _ResultStatusBadge(status: result.status),
        ],
      ),
    );
  }
}

class _MeasurementGrid extends StatelessWidget {
  final List<ExaminationMeasurementUiModel> measurements;

  const _MeasurementGrid({required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            '표시할 혈액검사 측정값이 없습니다.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width >= 900
            ? (width - 24) / 3
            : width >= 600
            ? (width - 12) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: measurements.map((measurement) {
            return SizedBox(
              width: cardWidth,
              child: _MeasurementCard(measurement: measurement),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final ExaminationMeasurementUiModel measurement;

  const _MeasurementCard({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final color = _abnormalColor(measurement.abnormalFlag);

    final referenceText = _formatReferenceText(
      measurement.referenceText?.trim() ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  measurement.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AbnormalBadge(label: measurement.abnormalLabel, color: color),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                measurement.displayValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: measurement.isAbnormal ? color : AppColors.textPrimary,
                ),
              ),
              if ((measurement.unit ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    measurement.unit!,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 7),

          Text(
            referenceText.isEmpty ? '정상범위 정보 없음' : '정상범위 $referenceText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHistoryCard extends StatelessWidget {
  final ExaminationResultUiModel result;

  const _ResultHistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final abnormalMeasurements = result.measurements
        .where((measurement) => measurement.isAbnormal)
        .toList();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 18,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(result.collectedAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '검사 #${result.examinationId} · '
                  '측정 ${result.measurements.length}개 · '
                  '이상 ${abnormalMeasurements.length}개',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          _ResultStatusBadge(status: result.status),
        ],
      ),
    );
  }
}

class _ResultStatusBadge extends StatelessWidget {
  final String status;

  const _ResultStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();

    final label = switch (normalized) {
      'FINAL' => '확정',
      'PRELIMINARY' => '예비',
      'DRAFT' => '초안',
      _ => status.isEmpty ? '-' : status,
    };

    final color = switch (normalized) {
      'FINAL' => AppColors.success,
      'PRELIMINARY' => AppColors.warning,
      'DRAFT' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AbnormalBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AbnormalBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

Color _abnormalColor(String? flag) {
  switch (flag?.trim().toUpperCase()) {
    case 'HIGH':
      return AppColors.danger;

    case 'LOW':
      return AppColors.primaryBlue;

    case 'NORMAL':
      return AppColors.success;

    default:
      return AppColors.textSecondary;
  }
}

String _formatDateTime(DateTime value) {
  final kst = value.toUtc().add(const Duration(hours: 9));

  final year = kst.year.toString();
  final month = kst.month.toString().padLeft(2, '0');
  final day = kst.day.toString().padLeft(2, '0');
  final hour = kst.hour.toString().padLeft(2, '0');
  final minute = kst.minute.toString().padLeft(2, '0');

  return '$year.$month.$day $hour:$minute';
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

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  });

  return normalized.replaceAll('<=', '≤').replaceAll('>=', '≥');
}
