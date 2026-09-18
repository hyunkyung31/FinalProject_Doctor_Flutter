import 'package:flutter/foundation.dart';

import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';

class PatientLabResultService {
  final ExaminationService examinationService;

  PatientLabResultService({required this.examinationService});

  Future<List<ExaminationResultUiModel>>
  fetchPatientLabResultsByExaminationIds({
    required Iterable<int> examinationIds,
  }) async {
    final totalStopwatch = Stopwatch()..start();

    final uniqueExaminationIds = examinationIds.where((id) => id > 0).toSet();

    if (uniqueExaminationIds.isEmpty) {
      totalStopwatch.stop();

      debugPrint(
        '[RESULT PERF] TOTAL: '
        '${totalStopwatch.elapsedMilliseconds}ms '
        '/ examinations=0',
      );

      return [];
    }

    Future<T> timed<T>(String name, Future<T> Function() action) async {
      final stopwatch = Stopwatch()..start();

      try {
        return await action();
      } finally {
        stopwatch.stop();

        debugPrint(
          '[RESULT PERF] $name: '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }

    // 혈액검사 ID에서 결과 목록을 바로 동시에 조회
    final resultGroups = await timed(
      'result lists (${uniqueExaminationIds.length} examinations)',
      () => Future.wait(
        uniqueExaminationIds.map(
          (examinationId) =>
              examinationService.fetchExaminationResults(examinationId),
        ),
      ),
    );

    final resultIds = <int>{};

    for (final results in resultGroups) {
      for (final result in results) {
        resultIds.add(result.id);
      }
    }

    if (resultIds.isEmpty) {
      totalStopwatch.stop();

      debugPrint(
        '[RESULT PERF] TOTAL: '
        '${totalStopwatch.elapsedMilliseconds}ms '
        '/ examinations=${uniqueExaminationIds.length} '
        '/ results=0',
      );

      return [];
    }

    // 상세 결과도 동시에 조회
    final details = await timed(
      'result details (${resultIds.length} results)',
      () => Future.wait(
        resultIds.map(
          (resultId) => timed(
            'detail $resultId',
            () => examinationService.fetchExaminationResultDetail(resultId),
          ),
        ),
      ),
    );

    final detailedResults = <ExaminationResultUiModel>[];

    for (final detail in details) {
      final bloodMeasurements = detail.measurements.where((measurement) {
        final code = measurement.code.trim().toUpperCase();

        return code != 'EF-TTE';
      }).toList();

      detailedResults.add(
        ExaminationResultUiModel(
          id: detail.id,
          resultType: detail.resultType,
          version: detail.version,
          collectedAt: detail.collectedAt,
          status: detail.status,
          createdAt: detail.createdAt,
          summaryText: detail.summaryText,
          confirmedAt: detail.confirmedAt,
          examinationId: detail.examinationId,
          confirmedBy: detail.confirmedBy,
          measurements: bloodMeasurements,
        ),
      );
    }

    detailedResults.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));

    totalStopwatch.stop();

    debugPrint(
      '[RESULT PERF] TOTAL: '
      '${totalStopwatch.elapsedMilliseconds}ms '
      '/ examinations=${uniqueExaminationIds.length} '
      '/ results=${resultIds.length}',
    );

    return detailedResults;
  }
}
