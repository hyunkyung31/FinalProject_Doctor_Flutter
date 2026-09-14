import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../imaging_ui_models.dart';

// ============================================================
// STEP 1. Info Tab
// ============================================================

enum _ImagingInfoTab { information, overlay }

// ============================================================
// STEP 2. Imaging Info Panel
// ============================================================

class ImagingInfoPanel extends StatefulWidget {
  final ImagingStudyUiModel study;
  final ImagingSeriesUiModel? series;

  final int currentIndex;
  final int totalCount;

  final ImagingViewerMode viewerMode;

  final bool segmentationEnabled;
  final bool cacEnabled;
  final bool bboxEnabled;
  final bool heatmapEnabled;

  final ValueChanged<ImagingViewerMode> onViewerModeChanged;

  final ValueChanged<bool> onSegmentationChanged;
  final ValueChanged<bool> onCacChanged;
  final ValueChanged<bool> onBboxChanged;
  final ValueChanged<bool> onHeatmapChanged;

  final VoidCallback onOpenOriginalViewer;

  const ImagingInfoPanel({
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
    required this.onViewerModeChanged,
    required this.onSegmentationChanged,
    required this.onCacChanged,
    required this.onBboxChanged,
    required this.onHeatmapChanged,
    required this.onOpenOriginalViewer,
  });

  @override
  State<ImagingInfoPanel> createState() => _ImagingInfoPanelState();
}

class _ImagingInfoPanelState extends State<ImagingInfoPanel> {
  _ImagingInfoTab _selectedTab = _ImagingInfoTab.information;

  // ============================================================
  // STEP 3. UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ======================================================
          // Tabs
          // ======================================================
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: _InfoTabButton(
                    label: '영상 정보',
                    selected: _selectedTab == _ImagingInfoTab.information,
                    onTap: () {
                      setState(() {
                        _selectedTab = _ImagingInfoTab.information;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: _InfoTabButton(
                    label: 'AI Overlay',
                    selected: _selectedTab == _ImagingInfoTab.overlay,
                    onTap: () {
                      setState(() {
                        _selectedTab = _ImagingInfoTab.overlay;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(13),
              child: _selectedTab == _ImagingInfoTab.information
                  ? _buildInformation()
                  : _buildOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 4. Information
  // ============================================================

  Widget _buildInformation() {
    return Column(
      children: [
        _InfoCard(
          title: 'Study 정보',
          icon: Icons.folder_open_outlined,
          children: [
            _InfoRow(label: 'Study ID', value: '#${widget.study.id}'),
            _InfoRow(
              label: 'Examination',
              value: '#${widget.study.examinationId}',
            ),
            _InfoRow(label: 'Modality', value: widget.study.modality),
            _InfoRow(label: '상태', value: widget.study.statusLabel),
            _InfoRow(label: 'Series', value: '${widget.study.seriesCount}'),
            _InfoRow(
              label: 'Instance',
              value: '${widget.currentIndex + 1} / ${widget.totalCount}',
            ),
            _InfoRow(
              label: '수신일',
              value: _formatDateTime(widget.study.createdAt),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _InfoCard(
          title: 'Series 정보',
          icon: Icons.layers_outlined,
          children: [
            _InfoRow(
              label: 'Series ID',
              value: widget.series == null ? '-' : '#${widget.series!.id}',
            ),
            _InfoRow(label: '설명', value: widget.series?.description ?? '정보 없음'),
            _InfoRow(label: 'Body Site', value: widget.series?.bodySite ?? '-'),
            _InfoRow(
              label: 'Orthanc',
              value: widget.study.orthancStudyId.isEmpty ? '미연결' : '연결됨',
            ),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onOpenOriginalViewer,
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text('원본 Viewer', style: TextStyle(fontSize: 10.5)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 5. Overlay
  // ============================================================

  Widget _buildOverlay() {
    final isCt = widget.study.modality == 'CT';
    final isXa = widget.study.modality == 'XA';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCt) ...[
          const Text(
            'Viewer Mode',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _ViewerModeButton(
                  label: '2D Slice',
                  selected: widget.viewerMode == ImagingViewerMode.slice2d,
                  onTap: () {
                    widget.onViewerModeChanged(ImagingViewerMode.slice2d);
                  },
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ViewerModeButton(
                  label: '3D 혈관',
                  selected: widget.viewerMode == ImagingViewerMode.vessel3d,
                  onTap: () {
                    widget.onViewerModeChanged(ImagingViewerMode.vessel3d);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _OverlaySwitch(
            title: 'Segmentation',
            subtitle: '혈관 분할 결과 Overlay',
            value: widget.segmentationEnabled,
            onChanged: widget.onSegmentationChanged,
          ),

          _OverlaySwitch(
            title: 'CAC Annotation',
            subtitle: '석회화 위치 표시',
            value: widget.cacEnabled,
            onChanged: widget.onCacChanged,
          ),

          const SizedBox(height: 12),

          _InfoCard(
            title: 'CAC Score',
            icon: Icons.analytics_outlined,
            children: const [
              _InfoRow(label: 'LAD', value: '-'),
              _InfoRow(label: 'LCX', value: '-'),
              _InfoRow(label: 'RCA', value: '-'),
              _InfoRow(label: 'Total', value: '-'),
            ],
          ),
        ],

        if (isXa) ...[
          _OverlaySwitch(
            title: 'Bounding Box',
            subtitle: 'AI 병변 위치 표시',
            value: widget.bboxEnabled,
            onChanged: widget.onBboxChanged,
          ),

          _OverlaySwitch(
            title: 'Heatmap',
            subtitle: 'Grad-CAM / XAI Overlay',
            value: widget.heatmapEnabled,
            onChanged: widget.onHeatmapChanged,
          ),
        ],

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'AI Overlay는 현재 UI Preview입니다. 실제 분석 결과 연결은 AI 화면 작업 후 연동합니다.',
            style: TextStyle(
              fontSize: 9,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 6. Tab Button
// ============================================================

class _InfoTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InfoTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.navy : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 7. Info Card
// ============================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.navy),

              const SizedBox(width: 6),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }
}

// ============================================================
// STEP 8. Info Row
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 9. Overlay Switch
// ============================================================

class _OverlaySwitch extends StatelessWidget {
  final String title;
  final String subtitle;

  final bool value;
  final ValueChanged<bool> onChanged;

  const _OverlaySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Transform.scale(
            scale: 0.75,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 10. Viewer Mode Button
// ============================================================

class _ViewerModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewerModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${date.year}.$month.$day $hour:$minute';
}
