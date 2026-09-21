import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_context.dart';

// ============================================================
// STEP 1. Viewer Controls
// ============================================================

class ImagingViewerControls extends StatelessWidget {
  final String modality;

  final int currentIndex;
  final int totalCount;

  final bool isPlaying;
  final double playbackSpeed;

  final double zoom;
  final bool panEnabled;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  final ValueChanged<int> onIndexChanged;
  final ValueChanged<double> onSpeedChanged;

  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  final VoidCallback onTogglePan;
  final VoidCallback onFit;
  final VoidCallback onReset;

  const ImagingViewerControls({
    super.key,
    required this.modality,
    required this.currentIndex,
    required this.totalCount,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.zoom,
    required this.panEnabled,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onStop,
    required this.onIndexChanged,
    required this.onSpeedChanged,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onTogglePan,
    required this.onFit,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isXa = modality == 'XA';

    final maxIndex = totalCount > 1 ? totalCount - 1 : 1;

    final sliderValue = currentIndex.clamp(0, maxIndex).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          // ======================================================
          // Frame / Slice
          // ======================================================
          Row(
            children: [
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                tooltip: isXa ? '이전 프레임' : '이전 Slice',
                onPressed: onPrevious,
              ),

              if (isXa) ...[
                const SizedBox(width: 5),

                _ControlButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  tooltip: isPlaying ? '일시정지' : '재생',
                  selected: isPlaying,
                  onPressed: onPlayPause,
                ),

                const SizedBox(width: 5),

                _ControlButton(
                  icon: Icons.stop_rounded,
                  tooltip: '정지',
                  onPressed: onStop,
                ),
              ],

              const SizedBox(width: 5),

              _ControlButton(
                icon: Icons.skip_next_rounded,
                tooltip: isXa ? '다음 프레임' : '다음 Slice',
                onPressed: onNext,
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 76,
                child: Text(
                  isXa
                      ? 'Frame ${currentIndex + 1} / $totalCount'
                      : 'Slice ${currentIndex + 1} / $totalCount',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: context.appTextSecondary,
                  ),
                ),
              ),

              Expanded(
                child: Slider(
                  value: sliderValue,
                  min: 0,
                  max: maxIndex.toDouble(),
                  divisions: totalCount > 1 ? maxIndex : null,
                  onChanged: totalCount <= 1
                      ? null
                      : (value) {
                          onIndexChanged(value.round());
                        },
                ),
              ),

              if (isXa) ...[
                const SizedBox(width: 8),

                PopupMenuButton<double>(
                  tooltip: '재생 속도',
                  onSelected: onSpeedChanged,
                  itemBuilder: (_) {
                    return const [
                      PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ];
                  },
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appSurfaceSoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 7),

          // ======================================================
          // Viewer Tools
          // ======================================================
          Row(
            children: [
              Text(
                'Viewer',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),

              const SizedBox(width: 10),

              _ToolButton(
                icon: Icons.remove_rounded,
                label: 'Zoom',
                onPressed: onZoomOut,
              ),

              const SizedBox(width: 5),

              _ToolButton(
                icon: Icons.add_rounded,
                label: '${(zoom * 100).round()}%',
                onPressed: onZoomIn,
              ),

              const SizedBox(width: 5),

              _ToolButton(
                icon: Icons.pan_tool_alt_outlined,
                label: 'Pan',
                selected: panEnabled,
                onPressed: onTogglePan,
              ),

              const SizedBox(width: 5),

              _ToolButton(
                icon: Icons.fit_screen_outlined,
                label: 'Fit',
                onPressed: onFit,
              ),

              const SizedBox(width: 5),

              _ToolButton(
                icon: Icons.refresh_rounded,
                label: 'Reset',
                onPressed: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 2. Control Button
// ============================================================

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  final bool selected;

  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : context.appSurfaceSoft,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : context.appBrand,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3. Tool Button
// ============================================================

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;

  final bool selected;

  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : context.appSurfaceSoft,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : context.appBrand,
            ),

            const SizedBox(width: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.appTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
