import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../presentation/appointment_ui_model.dart';

// ============================================================
// STEP 1. Appointment Service
// 실제 Staff Reservation API 연결
// ============================================================

class AppointmentService {
  final ApiClient apiClient;

  AppointmentService({required this.apiClient});

  // ==========================================================
  // STEP 2. 예약 목록 조회
  // GET /staff/reservations/
  // ==========================================================

  Future<List<AppointmentUiModel>> fetchAppointments() async {
    final response = await apiClient.dio.get(ApiEndpoints.staffReservations);

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

  // ============================================================
  // STEP 3. 예약 승인
  // POST /staff/reservations/{id}/accept/
  // ============================================================

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
