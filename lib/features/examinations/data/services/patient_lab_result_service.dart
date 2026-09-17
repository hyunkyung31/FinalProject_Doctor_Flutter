import '../../../examinations/data/services/examination_service.dart';
import '../../../examinations/presentation/examination_ui_models.dart';

class PatientLabResultService {
  final ExaminationService examinationService;

  PatientLabResultService({required this.examinationService});

  Future<List<ExaminationResultUiModel>> fetchPatientLabResults({
    required int patientId,
  }) async {
    final encounters = await examinationService.fetchEncounters();
    final orders = await examinationService.fetchExaminationOrders();
    final examinationTypes = await examinationService.fetchExaminationTypes();

    final patientEncounterIds = encounters
        .where((encounter) => encounter.patientId == patientId)
        .map((encounter) => encounter.id)
        .toSet();

    if (patientEncounterIds.isEmpty) {
      return [];
    }

    final labTypeIds = examinationTypes
        .where((type) => type.category.trim().toUpperCase() == 'LAB')
        .map((type) => type.id)
        .toSet();

    if (labTypeIds.isEmpty) {
      return [];
    }

    final patientLabOrders = orders.where((order) {
      return patientEncounterIds.contains(order.encounterId) &&
          labTypeIds.contains(order.examinationTypeId);
    }).toList();

    if (patientLabOrders.isEmpty) {
      return [];
    }

    final detailedResults = <ExaminationResultUiModel>[];
    final loadedResultIds = <int>{};

    for (final order in patientLabOrders) {
      final executions = await examinationService
          .fetchExaminationExecutionsByOrder(order.id);

      for (final execution in executions) {
        final results = await examinationService.fetchExaminationResults(
          execution.id,
        );

        for (final result in results) {
          if (!loadedResultIds.add(result.id)) {
            continue;
          }

          final detail = await examinationService.fetchExaminationResultDetail(
            result.id,
          );

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
      }
    }

    detailedResults.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));

    return detailedResults;
  }
}
