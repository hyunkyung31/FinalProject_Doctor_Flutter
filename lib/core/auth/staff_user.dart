// ============================================================
// STEP 1. 현재 로그인 의료진 모델
// GET /auth/staff/me/ 응답 기준
// ============================================================

class StaffUser {
  final int id;
  final String username;

  final int? staffId;
  final int? doctorId;

  final String name;

  final int? departmentId;
  final String departmentName;

  final String role;
  final List<String> roles;

  final String title;
  final String status;

  const StaffUser({
    required this.id,
    required this.username,
    required this.staffId,
    required this.doctorId,
    required this.name,
    required this.departmentId,
    required this.departmentName,
    required this.role,
    required this.roles,
    required this.title,
    required this.status,
  });

  // ============================================================
  // STEP 2. JSON → StaffUser
  // ============================================================

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int,

      username: json['username']?.toString() ?? '',

      staffId: _parseNullableInt(json['staff_id']),

      doctorId: _parseNullableInt(json['doctor_id']),

      name: json['name']?.toString() ?? '',

      departmentId: _parseNullableInt(json['department_id']),

      departmentName: json['department_name']?.toString() ?? '',

      role: json['role']?.toString() ?? '',

      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),

      title: json['title']?.toString() ?? '',

      status: json['status']?.toString() ?? '',
    );
  }

  // ============================================================
  // STEP 3. Nullable Int 변환
  // ============================================================

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ============================================================
  // STEP 4. 활성 계정 여부
  // ============================================================

  bool get isActive {
    return status.toUpperCase() == 'ACTIVE';
  }
}
