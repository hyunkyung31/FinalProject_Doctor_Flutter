import '../../../../core/network/api_client.dart';
import '../../presentation/questionnaire_ui_models.dart';

// ============================================================
// STEP 1. Appointment Questionnaire Service
// 기존 Backend API만 사용
//
// GET /staff/reservations/{reservationId}/questionnaire-response/
// ============================================================

class AppointmentQuestionnaireService {
  final ApiClient apiClient;

  const AppointmentQuestionnaireService({required this.apiClient});

  Future<List<QuestionnaireResponseUiModel>> fetchQuestionnaireResponses(
    int reservationId,
  ) async {
    final response = await apiClient.dio.get(
      '/staff/reservations/$reservationId/questionnaire-response/',
    );

    if (response.data is! List) {
      throw const FormatException('문진 응답 형식이 올바르지 않습니다.');
    }

    final results = (response.data as List)
        .whereType<Map>()
        .map(
          (item) => QuestionnaireResponseUiModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    results.sort((a, b) => a.templateId.compareTo(b.templateId));

    return results;
  }
}
