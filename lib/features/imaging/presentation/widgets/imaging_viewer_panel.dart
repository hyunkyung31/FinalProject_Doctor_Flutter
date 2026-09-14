import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../imaging_ui_models.dart';

// ============================================================
// STEP 1. Viewer Panel
// 실제 DICOM rendering 전 Mock Viewer
// ============================================================

class ImagingViewerPanel extends StatelessWidget {
  final ImagingStudyUiModel study;
  final ImagingSeriesUiModel? series;

  final int currentIndex;
  final int totalCount;

  final ImagingViewerMode viewerMode;

  final bool segmentationEnabled;
  final bool cacEnabled;
  final bool bboxEnabled;
  final bool heatmapEnabled;

  const ImagingViewerPanel({
    super.key,
    required this.study,
    required this.series,
    required this.currentIndex,
    required this.totalCount,
    required this.viewerMode,
    required this.segmentationEnabled,
    required this.cacEnabled,
    required this.bboxEnabled,
    required this.heatmapEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (study.status == 'ERROR' || study.errorCode != null) {
      return _buildErrorViewer();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D3444)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ======================================================
          // Viewer Center
          // ======================================================
          Positioned.fill(
            child: Center(
              child: viewerMode == ImagingViewerMode.vessel3d
                  ? _build3dViewer()
                  : _build2dViewer(),
            ),
          ),

          // ======================================================
          // Top Left Metadata
          // ======================================================
          Positioned(
            left: 14,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${study.modality} · Study #${study.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  series == null ? 'Series -' : 'Series #${series!.id}',
                  style: const TextStyle(fontSize: 9, color: Colors.white60),
                ),
              ],
            ),
          ),

          // ======================================================
          // Top Right Overlay
          // ======================================================
          Positioned(
            right: 12,
            top: 11,
            child: Wrap(
              spacing: 5,
              children: [
                if (segmentationEnabled) const _OverlayBadge(text: 'SEG'),
                if (cacEnabled) const _OverlayBadge(text: 'CAC'),
                if (bboxEnabled) const _OverlayBadge(text: 'BBOX'),
                if (heatmapEnabled) const _OverlayBadge(text: 'HEATMAP'),
              ],
            ),
          ),

          // ======================================================
          // Bottom Metadata
          // ======================================================
          Positioned(
            left: 14,
            bottom: 12,
            child: Text(
              study.modality == 'XA'
                  ? 'FRAME ${currentIndex + 1} / $totalCount'
                  : 'SLICE ${currentIndex + 1} / $totalCount',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2. 2D Viewer
  // ============================================================

  Widget _build2dViewer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          study.modality == 'XA'
              ? Icons.monitor_heart_outlined
              : Icons.view_in_ar_outlined,
          size: 62,
          color: Colors.white24,
        ),

        const SizedBox(height: 14),

        Text(
          study.modality == 'XA' ? 'CAG Cine Viewer' : 'DICOM Slice Viewer',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          '실제 DICOM Viewer 연결 전 UI Preview',
          style: TextStyle(fontSize: 9.5, color: Colors.white38),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 3. 3D Viewer
  // ============================================================

  Widget _build3dViewer() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hub_outlined, size: 68, color: Colors.white24),

        SizedBox(height: 14),

        Text(
          '3D Coronary Viewer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'LAD · LCX · LCA · RCA',
          style: TextStyle(fontSize: 9.5, color: Colors.white38),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 4. Error
  // ============================================================

  Widget _buildErrorViewer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071722),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.danger,
            ),

            const SizedBox(height: 12),

            const Text(
              '영상을 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              study.errorMessage ?? study.errorCode ?? '영상 오류',
              style: const TextStyle(fontSize: 9.5, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP 5. Overlay Badge
// ============================================================

class _OverlayBadge extends StatelessWidget {
  final String text;

  const _OverlayBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
      ),
    );
  }
}
