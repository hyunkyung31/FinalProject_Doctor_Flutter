import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/access_control.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Priority Patient Side Panel Open
// 오른쪽에서 Clinical Side Panel 표시
// ============================================================

void showPriorityPatientPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '우선 확인 환자 닫기',

    // Dashboard는 유지하고 뒤쪽만 살짝 어둡게 처리
    barrierColor: Colors.black.withValues(alpha: 0.18),

    transitionDuration: const Duration(milliseconds: 220),

    pageBuilder: (context, animation, secondaryAnimation) {
      return const Align(
        alignment: Alignment.centerRight,

        child: SafeArea(child: _PriorityPatientSidePanel()),
      );
    },

    // ==========================================================
    // 오른쪽 → 왼쪽 Slide Animation
    // ==========================================================
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(position: slideAnimation, child: child);
    },
  );
}

// ============================================================
// STEP 2. Priority Patient Side Panel
// ============================================================

class _PriorityPatientSidePanel extends StatelessWidget {
  const _PriorityPatientSidePanel();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isDoctor = auth.role == UserRole.doctor;

    return Material(
      color: Colors.transparent,

      child: Container(
        width: 410,

        margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(AppRadius.large),

          border: Border.all(color: AppColors.border),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // ==================================================
            // Header
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),

              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,

                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),

                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: AppColors.navy,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          '우선 확인 환자',

                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          '임상 우선순위가 높은 환자 3명',

                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: '닫기',

                    onPressed: () {
                      Navigator.of(context).pop();
                    },

                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ==================================================
            // Patient List
            // 글씨 확대 시 Panel 내부 Scroll 가능
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),

                child: Column(
                  children: [
                    // ============================================
                    // Patient 1
                    // ============================================
                    _PriorityPatientItem(
                      name: '박OO',
                      age: '78세',
                      status: 'HIGH',
                      danger: true,

                      clinicalParts: isDoctor
                          ? const [
                              _PriorityClinicalTextPart(text: 'CAD Risk '),

                              _PriorityClinicalTextPart(
                                text: '87% ↑',
                                emphasize: true,
                                danger: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  EF '),

                              _PriorityClinicalTextPart(
                                text: '28% ↓',
                                emphasize: true,
                                danger: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  심부전'),
                            ]
                          : const [
                              _PriorityClinicalTextPart(text: '혈압 '),

                              _PriorityClinicalTextPart(
                                text: '재측정 필요',
                                emphasize: true,
                                danger: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  활력징후 확인'),
                            ],
                    ),

                    const Divider(height: 1),

                    // ============================================
                    // Patient 2
                    // ============================================
                    _PriorityPatientItem(
                      name: '이OO',
                      age: '65세',
                      status: 'WATCH',

                      clinicalParts: isDoctor
                          ? const [
                              _PriorityClinicalTextPart(text: 'CAC Score '),

                              _PriorityClinicalTextPart(
                                text: '상승',
                                emphasize: true,
                              ),

                              _PriorityClinicalTextPart(
                                text: '  ·  다혈관 관상동맥질환',
                              ),
                            ]
                          : const [
                              _PriorityClinicalTextPart(text: 'CCTA '),

                              _PriorityClinicalTextPart(
                                text: '13:30 예정',
                                emphasize: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  검사 전 확인'),
                            ],
                    ),

                    const Divider(height: 1),

                    // ============================================
                    // Patient 3
                    // ============================================
                    _PriorityPatientItem(
                      name: '정OO',
                      age: '72세',
                      status: 'WATCH',

                      clinicalParts: isDoctor
                          ? const [
                              _PriorityClinicalTextPart(text: 'CAG '),

                              _PriorityClinicalTextPart(
                                text: '병변 의심',
                                emphasize: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  AI 검토 대기'),
                            ]
                          : const [
                              _PriorityClinicalTextPart(text: 'AI 결과 '),

                              _PriorityClinicalTextPart(
                                text: '확인 대기',
                                emphasize: true,
                              ),

                              _PriorityClinicalTextPart(text: '  ·  의료진 검토 예정'),
                            ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // ==================================================
            // Footer
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '위험도와 임상 상태를 기준으로 정렬',

                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

                      _showPriorityMessage(context, '전체 환자 목록으로 이동');
                    },

                    icon: const Icon(Icons.people_outline_rounded, size: 15),

                    label: const Text('전체 환자 보기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Priority Clinical Text Data
// 이 패널 내부에서만 사용하는 Private Data Class
// ============================================================

class _PriorityClinicalTextPart {
  final String text;
  final bool emphasize;
  final bool danger;

  const _PriorityClinicalTextPart({
    required this.text,
    this.emphasize = false,
    this.danger = false,
  });
}

// ============================================================
// STEP 4. Priority Patient Item
// ============================================================

class _PriorityPatientItem extends StatelessWidget {
  final String name;
  final String age;
  final String status;

  final List<_PriorityClinicalTextPart> clinicalParts;

  final bool danger;

  const _PriorityPatientItem({
    required this.name,
    required this.age,
    required this.status,
    required this.clinicalParts,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showPriorityMessage(context, '$name 환자 확인');
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // 환자명 + 위험도
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$name · $age',

                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _PriorityStatusTag(text: status, danger: danger),
              ],
            ),

            const SizedBox(height: 7),

            // ==================================================
            // 임상 정보
            // ==================================================
            Text.rich(
              TextSpan(
                children: [
                  for (final part in clinicalParts)
                    TextSpan(
                      text: part.text,

                      style: TextStyle(
                        color: part.danger
                            ? AppColors.danger
                            : part.emphasize
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,

                        fontSize: part.emphasize ? 10.8 : 10.3,

                        fontWeight: part.emphasize
                            ? FontWeight.w700
                            : FontWeight.w500,

                        height: 1.4,
                      ),
                    ),
                ],
              ),

              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 5. Priority Status Tag
// Side Panel 전용 HIGH / WATCH Tag
// ============================================================

class _PriorityStatusTag extends StatelessWidget {
  final String text;
  final bool danger;

  const _PriorityStatusTag({required this.text, required this.danger});

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? AppColors.dangerBackground
        : AppColors.warningBackground;

    final foreground = danger ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(AppRadius.round),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// STEP 6. Temporary Message
// 추후 실제 Routing 연결 시 제거 예정
// ============================================================

void _showPriorityMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),

        duration: const Duration(milliseconds: 900),
      ),
    );
}
