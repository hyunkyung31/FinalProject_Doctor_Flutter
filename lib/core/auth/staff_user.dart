// ============================================================
// STEP 1. 현재 로그인 의료진 모델
// GET /staff/me/ 응답 기준
// ============================================================

class StaffUser {
  final int id;
  final String username;
  final String status;
  final List<String> roles;

  const StaffUser({
    required this.id,
    required this.username,
    required this.status,
    required this.roles,
  });

  // ============================================================
  // STEP 2. JSON → StaffUser
  // ============================================================

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int,
      username: json['username']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),
    );
  }

  // ============================================================
  // STEP 3. 활성 계정 여부
  // ============================================================

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
