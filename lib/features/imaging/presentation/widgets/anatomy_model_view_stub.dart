import 'package:flutter/material.dart';

const bool anatomyWebViewerAvailable = false;

class AnatomyModelView extends StatelessWidget {
  final String sourceUrl;
  final String format;
  final String viewMode;

  const AnatomyModelView({
    super.key,
    required this.sourceUrl,
    this.format = 'GLB',
    this.viewMode = 'VESSEL_CALCIFICATION',
  });

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF050A16),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '심장 모형이 포함된 3D는 웹과 같은 WebGL 뷰어에서 표시됩니다.\n'
            '브라우저로 실행한 Flutter web 화면에서 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }
}
