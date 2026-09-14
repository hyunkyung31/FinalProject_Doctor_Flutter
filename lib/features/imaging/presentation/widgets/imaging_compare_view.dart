import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../imaging_ui_models.dart';

// ============================================================
// STEP 1. Compare View
// ============================================================

class ImagingCompareView extends StatefulWidget {
  final ImagingStudyUiModel currentStudy;
  final ImagingStudyUiModel comparisonStudy;

  final VoidCallback onClose;

  const ImagingCompareView({
    super.key,
    required this.currentStudy,
    required this.comparisonStudy,
    required this.onClose,
  });

  @override
  State<ImagingCompareView> createState() => _ImagingCompareViewState();
}

class _ImagingCompareViewState extends State<ImagingCompareView> {
  bool _synchronized = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ======================================================
        // Header
        // ======================================================
        Row(
          children: [
            const Expanded(
              child: Text(
                '이전 · 현재 영상 비교',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '동기화 이동',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),

                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _synchronized,
                    onChanged: (value) {
                      setState(() {
                        _synchronized = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            OutlinedButton.icon(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('비교 종료', style: TextStyle(fontSize: 10.5)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ======================================================
        // Viewers
        // ======================================================
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _CompareViewer(
                  label: '이전 영상',
                  study: widget.comparisonStudy,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _CompareViewer(
                  label: '현재 영상',
                  study: widget.currentStudy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 2. Compare Viewer
// ============================================================

class _CompareViewer extends StatelessWidget {
  final String label;
  final ImagingStudyUiModel study;

  const _CompareViewer({required this.label, required this.study});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071722),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    size: 60,
                    color: Colors.white24,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'DICOM Viewer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 14,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${study.modality} · Study #${study.id}',
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),

                const SizedBox(height: 2),

                Text(
                  '${study.instanceCount} instances',
                  style: const TextStyle(fontSize: 8.5, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
