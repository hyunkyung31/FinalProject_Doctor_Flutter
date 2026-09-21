class AppointmentDoctorUiModel {
  final int id;
  final int userId;
  final int departmentId;
  final String departmentName;
  final String name;
  final String title;
  final String contact;
  final bool isActive;

  const AppointmentDoctorUiModel({
    required this.id,
    required this.userId,
    required this.departmentId,
    required this.departmentName,
    required this.name,
    required this.title,
    required this.contact,
    required this.isActive,
  });

  factory AppointmentDoctorUiModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDoctorUiModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user']),
      departmentId: _parseInt(json['department']),
      departmentName: json['department_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
