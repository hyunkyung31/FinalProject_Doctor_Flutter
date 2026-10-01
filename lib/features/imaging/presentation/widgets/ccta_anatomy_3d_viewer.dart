import 'package:flutter/material.dart';
import 'package:model_viewer_pro/model_viewer_pro.dart';

// ============================================================
// STEP 1. CCTA Anatomy GLB Viewer
//
// assets/models/anatomy.glb 내부 mesh 이름:
// - heart
// - aorta
// - coronary
// - calcification
//
// React에서 사용하던 anatomy.glb를 Flutter에서도 동일하게 사용한다.
// 이 모델은 현재 환자별 생성 모델이 아니라 해부학 참조/데모 모델이다.
//
// interactionEnabled:
// - true  : 3D 회전 / 확대 / 이동
// - false : 3D 조작 잠금 + Annotation Overlay 드로우
// ============================================================

enum CctaAnatomyViewMode {
  all,
  heart,
  vessel,
  calcification,
  vesselCalcification,
}

class CctaAnatomy3DViewer extends StatefulWidget {
  final String assetPath;

  // true  : 3D 회전 / 확대 / 이동 가능
  // false : 3D 조작을 막고 Annotation Overlay에서 드로우
  final bool interactionEnabled;

  // 3D Stage 전체 크기를 기준으로 Annotation Overlay 생성
  final Widget Function(Size stageSize)? stageOverlayBuilder;

  const CctaAnatomy3DViewer({
    super.key,
    this.assetPath = 'assets/models/anatomy.glb',
    this.interactionEnabled = true,
    this.stageOverlayBuilder,
  });

  @override
  State<CctaAnatomy3DViewer> createState() => _CctaAnatomy3DViewerState();
}

class _CctaAnatomy3DViewerState extends State<CctaAnatomy3DViewer> {
  final ModelViewerProController _controller = ModelViewerProController();

  List<String> _availableMeshes = const [];

  CctaAnatomyViewMode _viewMode = CctaAnatomyViewMode.all;

  bool _loading = true;
  bool _autoRotate = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // STEP 2. GLB Mesh 탐색
  // ============================================================

  String? _meshFor(String keyword) {
    final normalized = keyword.toLowerCase();

    for (final name in _availableMeshes) {
      if (name.toLowerCase() == normalized) {
        return name;
      }
    }

    for (final name in _availableMeshes) {
      if (name.toLowerCase().contains(normalized)) {
        return name;
      }
    }

    return null;
  }

  Future<void> _applyViewMode(CctaAnatomyViewMode mode) async {
    final heart = _meshFor('heart');
    final aorta = _meshFor('aorta');
    final coronary = _meshFor('coronary');
    final calcification = _meshFor('calcification');

    bool heartVisible = false;
    bool aortaVisible = false;
    bool coronaryVisible = false;
    bool calcificationVisible = false;

    switch (mode) {
      case CctaAnatomyViewMode.all:
        heartVisible = true;
        aortaVisible = true;
        coronaryVisible = true;
        calcificationVisible = true;
        break;

      case CctaAnatomyViewMode.heart:
        heartVisible = true;
        break;

      case CctaAnatomyViewMode.vessel:
        aortaVisible = true;
        coronaryVisible = true;
        break;

      case CctaAnatomyViewMode.calcification:
        calcificationVisible = true;
        break;

      case CctaAnatomyViewMode.vesselCalcification:
        aortaVisible = true;
        coronaryVisible = true;
        calcificationVisible = true;
        break;
    }

    final operations = <Future<void>>[];

    if (heart != null) {
      operations.add(_controller.setVisibility(heart, heartVisible));
    }

    if (aorta != null) {
      operations.add(_controller.setVisibility(aorta, aortaVisible));
    }

    if (coronary != null) {
      operations.add(_controller.setVisibility(coronary, coronaryVisible));
    }

    if (calcification != null) {
      operations.add(
        _controller.setVisibility(calcification, calcificationVisible),
      );
    }

    await Future.wait(operations);

    if (!mounted) {
      return;
    }

    setState(() {
      _viewMode = mode;
    });
  }

  Future<void> _handleLoaded(List<String> meshes) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _availableMeshes = meshes;
      _loading = false;
      _message = null;
    });

    debugPrint('[CCTA ANATOMY GLB] meshes=$meshes');

    final required = ['heart', 'aorta', 'coronary', 'calcification'];

    final missing = required
        .where((keyword) => _meshFor(keyword) == null)
        .toList();

    if (missing.isNotEmpty && mounted) {
      setState(() {
        _message = 'GLB에서 일부 구조를 찾지 못했습니다: ${missing.join(', ')}';
      });
    }

    await _applyViewMode(CctaAnatomyViewMode.all);
  }

  // ============================================================
  // STEP 3. Camera Controls
  // ============================================================

  Future<void> _toggleAutoRotate() async {
    final next = !_autoRotate;

    await _controller.setAutoRotate(next);

    if (!mounted) {
      return;
    }

    setState(() {
      _autoRotate = next;
    });
  }

  // ============================================================
  // STEP 4. Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050A10),
      child: Column(
        children: [
          _buildToolbar(),

          // ====================================================
          // 3D Stage
          // ====================================================
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stageSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ==================================================
                    // 3D Model
                    // ==================================================
                    ModelViewerProViewer(
                      src: widget.assetPath,
                      controller: _controller,
                      backgroundColor: const Color(0xFF050A10),

                      // Navigation 모드에서만
                      // 3D 회전 / 확대 / 이동을 허용한다.
                      cameraControls: widget.interactionEnabled,

                      autoRotate: false,
                      ar: false,
                      exposure: 1.05,
                      shadowIntensity: 0,
                      fieldOfView: '30deg',

                      disablePan: !widget.interactionEnabled,
                      disableZoom: !widget.interactionEnabled,
                      disableTap: !widget.interactionEnabled,

                      touchAction: 'none',

                      initialLoadingMeshes: const [
                        'heart',
                        'aorta',
                        'coronary',
                        'calcification',
                      ],

                      onLoad: _handleLoaded,
                    ),

                    // ==================================================
                    // Loading Overlay
                    // ==================================================
                    if (_loading)
                      Container(
                        color: const Color(0xAA050A10),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(height: 12),
                            Text(
                              'anatomy.glb 로딩 중...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ==================================================
                    // Reference Badge
                    // ==================================================
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Badge(
                        label: 'REFERENCE ANATOMY · GLB',
                        color: const Color(0xCC274765),
                      ),
                    ),

                    // ==================================================
                    // Camera Control Buttons
                    // ==================================================
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Row(
                        children: [
                          _CameraButton(
                            tooltip: '축소',
                            icon: Icons.remove_rounded,
                            onPressed: _loading || !widget.interactionEnabled
                                ? null
                                : _controller.zoomOut,
                          ),
                          const SizedBox(width: 5),
                          _CameraButton(
                            tooltip: '확대',
                            icon: Icons.add_rounded,
                            onPressed: _loading || !widget.interactionEnabled
                                ? null
                                : _controller.zoomIn,
                          ),
                          const SizedBox(width: 5),
                          _CameraButton(
                            tooltip: _autoRotate ? '자동 회전 정지' : '자동 회전',
                            icon: _autoRotate
                                ? Icons.pause_circle_outline_rounded
                                : Icons.threesixty_rounded,
                            selected: _autoRotate,
                            onPressed: _loading || !widget.interactionEnabled
                                ? null
                                : _toggleAutoRotate,
                          ),
                          const SizedBox(width: 5),
                          _CameraButton(
                            tooltip: '카메라 초기화',
                            icon: Icons.restart_alt_rounded,
                            onPressed: _loading || !widget.interactionEnabled
                                ? null
                                : _controller.resetCamera,
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // GLB Message
                    // ==================================================
                    if (_message != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE61A2B3E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orangeAccent.shade100,
                            ),
                          ),
                          child: Text(
                            _message!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                    // ==================================================
                    // Annotation Overlay
                    //
                    // Navigation Mode
                    //   interactionEnabled = true
                    //   → Overlay가 pointer 무시
                    //   → 아래 3D Viewer 조작
                    //
                    // Draw Mode
                    //   interactionEnabled = false
                    //   → Overlay가 pointer 수신
                    //   → 3D Viewer 위에 Annotation 작성
                    // ==================================================
                    if (widget.stageOverlayBuilder != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: widget.interactionEnabled,
                          child: widget.stageOverlayBuilder!(stageSize),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          _buildLegend(),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 5. Structure Toolbar
  // ============================================================

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A28),
        border: Border(bottom: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.view_in_ar_outlined,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 7),
          const Text(
            '3D Anatomy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ViewButton(
                    label: '전체',
                    selected: _viewMode == CctaAnatomyViewMode.all,
                    onTap: () => _applyViewMode(CctaAnatomyViewMode.all),
                  ),
                  _ViewButton(
                    label: '심장',
                    selected: _viewMode == CctaAnatomyViewMode.heart,
                    onTap: () => _applyViewMode(CctaAnatomyViewMode.heart),
                  ),
                  _ViewButton(
                    label: '혈관',
                    selected: _viewMode == CctaAnatomyViewMode.vessel,
                    onTap: () => _applyViewMode(CctaAnatomyViewMode.vessel),
                  ),
                  _ViewButton(
                    label: '석회화',
                    selected: _viewMode == CctaAnatomyViewMode.calcification,
                    onTap: () =>
                        _applyViewMode(CctaAnatomyViewMode.calcification),
                  ),
                  _ViewButton(
                    label: '혈관 + 석회화',
                    selected:
                        _viewMode == CctaAnatomyViewMode.vesselCalcification,
                    onTap: () =>
                        _applyViewMode(CctaAnatomyViewMode.vesselCalcification),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 6. Legend
  // ============================================================

  Widget _buildLegend() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A28),
        border: Border(top: BorderSide(color: Color(0xFF22364B))),
      ),
      child: Row(
        children: [
          const _LegendDot(color: Color(0xFFE9A6AF), label: '심장'),
          const SizedBox(width: 14),
          const _LegendDot(color: Color(0xFFB22222), label: '대동맥'),
          const SizedBox(width: 14),
          const _LegendDot(color: Color(0xFF4169E1), label: '관상동맥'),
          const SizedBox(width: 14),
          const _LegendDot(color: Color(0xFFFFA500), label: '석회화'),
          const Spacer(),
          Text(
            widget.interactionEnabled
                ? 'Drag 회전 · Pinch 확대/축소'
                : 'Annotation 드로우 모드',
            style: const TextStyle(color: Colors.white38, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 7. Structure View Button
// ============================================================

class _ViewButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: selected
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(label, style: const TextStyle(fontSize: 8.8)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white12),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(label, style: const TextStyle(fontSize: 8.8)),
            ),
    );
  }
}

// ============================================================
// STEP 8. Camera Button
// ============================================================

class _CameraButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const _CameraButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF315E8C)
              : const Color(0xCC132235),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white24,
          minimumSize: const Size(32, 32),
          maximumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

// ============================================================
// STEP 9. Legend Dot
// ============================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 8.2),
        ),
      ],
    );
  }
}

// ============================================================
// STEP 10. Badge
// ============================================================

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
