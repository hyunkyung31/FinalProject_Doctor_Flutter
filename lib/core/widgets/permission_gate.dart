import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/access_control.dart';
import '../auth/auth_provider.dart';

// ============================================================
// STEP 1. 권한이 없을 때의 UI 처리 방식
// ============================================================

enum PermissionDeniedMode {
  // 화면에서 완전히 숨김
  hidden,

  // 화면에는 보이지만 사용 불가
  disabled,
}

// ============================================================
// STEP 2. Permission Gate
// 권한에 따라 Widget 표시 여부 및 활성 상태 제어
// ============================================================

class PermissionGate extends StatelessWidget {
  final AppPermission permission;

  final Widget child;

  final PermissionDeniedMode deniedMode;

  final String? disabledMessage;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.deniedMode = PermissionDeniedMode.hidden,
    this.disabledMessage,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final hasPermission = auth.hasPermission(permission);

    // ==========================================================
    // STEP 3. 권한이 있는 경우
    // ==========================================================

    if (hasPermission) {
      return child;
    }

    // ==========================================================
    // STEP 4. 권한이 없고 hidden 모드인 경우
    // ==========================================================

    if (deniedMode == PermissionDeniedMode.hidden) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // STEP 5. 권한이 없고 disabled 모드인 경우
    // ==========================================================

    return Tooltip(
      message: disabledMessage ?? '현재 계정에는 이 기능을 사용할 권한이 없습니다.',

      child: IgnorePointer(child: Opacity(opacity: 0.40, child: child)),
    );
  }
}
