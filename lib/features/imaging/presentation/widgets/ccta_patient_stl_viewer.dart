import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_doctor/core/theme/app_theme_context.dart';

// ============================================================
// STEP 1. Patient-specific Calcification STL Viewer
//
// Backend CALCIFICATION_ONLY STL을 표시한다.
// anatomy.glb와 달리 실제 AI 분석 결과의 환자별 석회화 mesh 용도다.
// ============================================================

class CctaPatientStlViewer extends StatefulWidget {
  final Uint8List bytes;
  const CctaPatientStlViewer({super.key, required this.bytes});

  @override
  State<CctaPatientStlViewer> createState() => _CctaPatientStlViewerState();
}

class _CctaPatientStlViewerState extends State<CctaPatientStlViewer> {
  late _Mesh _mesh;
  double _yaw = -.55;
  double _pitch = .3;
  double _zoom = 1.35;
  double _startZoom = 1.35;

  @override
  void initState() {
    super.initState();
    _mesh = _Mesh.parse(widget.bytes);
  }

  @override
  void didUpdateWidget(covariant CctaPatientStlViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _mesh = _Mesh.parse(widget.bytes);
      _yaw = -.55;
      _pitch = .3;
      _zoom = 1.35;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mesh.triangles.isEmpty) {
      return const Center(child: Text('3D 모델 데이터를 읽지 못했습니다.'));
    }

    void resetView() {
      setState(() {
        _yaw = -.55;
        _pitch = .3;
        _zoom = 1.35;
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: resetView,
      onScaleStart: (_) {
        _startZoom = _zoom;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount >= 2) {
            _zoom = (_startZoom * details.scale).clamp(.45, 4.0).toDouble();
          } else {
            _yaw += details.focalPointDelta.dx * .01;

            _pitch = (_pitch + details.focalPointDelta.dy * .01)
                .clamp(-1.4, 1.4)
                .toDouble();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MeshPainter(
              mesh: _mesh,
              yaw: _yaw,
              pitch: _pitch,
              zoom: _zoom,
              base: Theme.of(context).colorScheme.primary,
              edge: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: .22),
            ),
          ),

          // ======================================================
          // 석회화 모델 안내
          // ======================================================
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    size: 15,
                    color: context.appTextPrimary,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    '환자 AI 석회화 3D',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // 초기화 버튼
          // ======================================================
          Positioned(
            right: 14,
            top: 14,
            child: IconButton.filledTonal(
              tooltip: '3D 화면 초기화',
              onPressed: resetView,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
            ),
          ),

          // ======================================================
          // 조작 안내
          // ======================================================
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Drag 회전 · Pinch 확대/축소 · 두 번 탭 초기화',
                style: TextStyle(fontSize: 9, color: context.appTextSecondary),
              ),
            ),
          ),

          // ======================================================
          // 임상 오해 방지 안내
          // ======================================================
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '현재 모델은 혈관 전체가 아닌 '
                'AI 분할 석회화 영역을 표시합니다.',
                style: TextStyle(
                  fontSize: 8.5,
                  height: 1.4,
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mesh {
  final List<_Tri> triangles;
  const _Mesh(this.triangles);

  factory _Mesh.parse(Uint8List bytes) {
    const maxTriangles = 12000;
    List<_Tri> raw = [];

    if (bytes.length >= 84) {
      final data = ByteData.sublistView(bytes);
      final count = data.getUint32(80, Endian.little);
      final expected = 84 + count * 50;
      if (count > 0 && expected <= bytes.length) {
        final step = math.max(1, (count / maxTriangles).ceil()).toInt();
        for (var i = 0; i < count; i += step) {
          final o = 84 + i * 50;
          _V v(int x) => _V(
            data.getFloat32(o + x, Endian.little),
            data.getFloat32(o + x + 4, Endian.little),
            data.getFloat32(o + x + 8, Endian.little),
          );
          raw.add(_Tri(v(12), v(24), v(36)));
          if (raw.length >= maxTriangles) {
            break;
          }
        }
      }
    }

    if (raw.isEmpty) {
      final text = utf8.decode(bytes, allowMalformed: true);
      if (text.trimLeft().toLowerCase().startsWith('solid')) {
        final re = RegExp(
          r'vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)',
          caseSensitive: false,
        );
        final vertices = <_V>[];
        for (final m in re.allMatches(text)) {
          final x = double.tryParse(m.group(1) ?? '');
          final y = double.tryParse(m.group(2) ?? '');
          final z = double.tryParse(m.group(3) ?? '');
          if (x != null && y != null && z != null) {
            vertices.add(_V(x, y, z));
          }
        }
        final count = vertices.length ~/ 3;
        final step = math.max(1, (count / maxTriangles).ceil()).toInt();
        for (var i = 0; i < count; i += step) {
          final p = i * 3;
          raw.add(_Tri(vertices[p], vertices[p + 1], vertices[p + 2]));
          if (raw.length >= maxTriangles) {
            break;
          }
        }
      }
    }

    if (raw.isEmpty) {
      return const _Mesh([]);
    }

    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;
    for (final t in raw) {
      for (final v in [t.a, t.b, t.c]) {
        minX = math.min(minX, v.x);
        minY = math.min(minY, v.y);
        minZ = math.min(minZ, v.z);
        maxX = math.max(maxX, v.x);
        maxY = math.max(maxY, v.y);
        maxZ = math.max(maxZ, v.z);
      }
    }
    final cx = (minX + maxX) / 2,
        cy = (minY + maxY) / 2,
        cz = (minZ + maxZ) / 2;
    final extent = math.max(maxX - minX, math.max(maxY - minY, maxZ - minZ));
    final scale = extent.abs() < 1e-9 ? 1.0 : extent;
    _V n(_V v) =>
        _V((v.x - cx) / scale, (v.y - cy) / scale, (v.z - cz) / scale);
    return _Mesh([for (final t in raw) _Tri(n(t.a), n(t.b), n(t.c))]);
  }
}

class _MeshPainter extends CustomPainter {
  final _Mesh mesh;
  final double yaw, pitch, zoom;
  final Color base, edge;
  const _MeshPainter({
    required this.mesh,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.base,
    required this.edge,
  });

  _V rot(_V s) {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x = s.x * cy + s.z * sy;
    final z1 = -s.x * sy + s.z * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    return _V(x, s.y * cp - z1 * sp, s.y * sp + z1 * cp);
  }

  Offset project(_V v, Size size) {
    final scale = math.min(size.width, size.height) * .82 * zoom;
    final perspective = 1 / (1.75 + v.z * .55);
    return Offset(
      size.width / 2 + v.x * scale * perspective,
      size.height / 2 - v.y * scale * perspective,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = <_PaintTri>[];
    for (final t in mesh.triangles) {
      final a = rot(t.a), b = rot(t.b), c = rot(t.c);
      final ab = b - a, ac = c - a;
      var nx = ab.y * ac.z - ab.z * ac.y;
      var ny = ab.z * ac.x - ab.x * ac.z;
      var nz = ab.x * ac.y - ab.y * ac.x;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 1e-9) {
        nx /= len;
        ny /= len;
        nz /= len;
      }
      if (nz > .18) {
        continue;
      }
      final light = (.42 + (-nz * .45) + (-ny * .12))
          .clamp(.18, .96)
          .toDouble();
      rows.add(
        _PaintTri(
          project(a, size),
          project(b, size),
          project(c, size),
          (a.z + b.z + c.z) / 3,
          light,
        ),
      );
    }
    rows.sort((a, b) => a.depth.compareTo(b.depth));
    for (final t in rows) {
      final path = Path()
        ..moveTo(t.a.dx, t.a.dy)
        ..lineTo(t.b.dx, t.b.dy)
        ..lineTo(t.c.dx, t.c.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(Colors.black, base, t.light)!
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = .35,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.mesh != mesh ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom ||
      old.base != base;
}

class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);
  _V operator -(_V o) => _V(x - o.x, y - o.y, z - o.z);
}

class _Tri {
  final _V a, b, c;
  const _Tri(this.a, this.b, this.c);
}

class _PaintTri {
  final Offset a, b, c;
  final double depth, light;
  const _PaintTri(this.a, this.b, this.c, this.depth, this.light);
}
