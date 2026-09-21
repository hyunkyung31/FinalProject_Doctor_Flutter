import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../presentation/appointment_ui_model.dart';

class AppointmentService {
  final ApiClient apiClient;

  AppointmentService({required this.apiClient});

  Future<List<AppointmentUiModel>> fetchAppointments({int? doctorId}) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.staffReservations,
      queryParameters: {'doctor_id': ?doctorId},
    );

    if (response.data is! List) {
      throw const FormatException('예약 목록 응답 형식이 올바르지 않습니다.');
    }

    final data = response.data as List;

    return data.map((item) {
      if (item is! Map) {
        throw const FormatException('예약 데이터 형식이 올바르지 않습니다.');
      }

      return AppointmentUiModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> acceptAppointment({
    required int reservationId,
    required int doctorId,
  }) async {
    await apiClient.dio.post(
      ApiEndpoints.staffReservationAccept(reservationId),
      data: {'doctor_id': doctorId},
    );
  }
}
