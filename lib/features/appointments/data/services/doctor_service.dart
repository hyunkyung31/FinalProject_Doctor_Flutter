import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../presentation/appointment_doctor_ui_model.dart';

class DoctorService {
  final ApiClient apiClient;

  DoctorService({required this.apiClient});

  Future<List<AppointmentDoctorUiModel>> fetchDoctors() async {
    final response = await apiClient.dio.get(ApiEndpoints.doctors);

    if (response.data is! Map) {
      throw const FormatException('의료진 목록 응답 형식이 올바르지 않습니다.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);

    final results = data['results'];

    if (results is! List) {
      throw const FormatException('의료진 results 형식이 올바르지 않습니다.');
    }

    return results
        .whereType<Map>()
        .map(
          (item) => AppointmentDoctorUiModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((doctor) => doctor.id > 0)
        .toList();
  }
}
