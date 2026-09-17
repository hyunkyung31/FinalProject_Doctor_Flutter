import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ============================================================
// STEP 1. Patient Responsive Layout
// ============================================================

class PatientResponsiveLayout extends StatelessWidget {
  final Widget patientList;
  final Widget patientDetail;

  final bool showCompactDetail;
  final VoidCallback onBackToList;

  final double breakpoint;

  const PatientResponsiveLayout({
    super.key,
    required this.patientList,
    required this.patientDetail,
    required this.showCompactDetail,
    required this.onBackToList,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < breakpoint;

        // ========================================================
        // Wide Layout
        // 환자 목록 + 환자 상세 동시 표시
        // ========================================================

        if (!isCompact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: patientList),

              const SizedBox(width: 14),

              Expanded(flex: 7, child: patientDetail),
            ],
          );
        }

        // ========================================================
        // Compact Layout
        // 목록 / 상세 중 하나만 표시
        //
        // IndexedStack 사용:
        // 상세 화면에 갔다 돌아와도 목록 Widget 상태 유지
        // ========================================================

        return IndexedStack(
          index: showCompactDetail ? 1 : 0,
          children: [
            // ====================================================
            // Patient List
            // ====================================================
            patientList,

            // ====================================================
            // Patient Detail
            // ====================================================
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompactBackBar(onBackToList: onBackToList),

                const SizedBox(height: 6),

                Expanded(child: patientDetail),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// STEP 2. Compact Detail Back Button
// 세로형 상세 화면 → 환자 목록 복귀
// 시각적 크기는 작게 유지하고 터치 영역만 확보
// ============================================================

class _CompactBackBar extends StatelessWidget {
  final VoidCallback onBackToList;

  const _CompactBackBar({required this.onBackToList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBackToList,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 110,
              height: 36,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),

                    SizedBox(width: 7),

                    Text(
                      '환자 목록',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
