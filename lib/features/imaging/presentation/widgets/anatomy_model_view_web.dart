import 'dart:js_interop';

import 'package:flutter/material.dart';

const bool anatomyWebViewerAvailable = true;

@JS('AngioAnatomy.mount')
external void _mountAnatomy(
  JSObject element,
  JSString sourceUrl,
  JSString format,
  JSString viewMode,
  JSFunction onStatus,
  JSFunction onError,
);

@JS('AngioAnatomy.setViewMode')
external void _setAnatomyViewMode(JSObject element, JSString viewMode);

@JS('AngioAnatomy.dispose')
external void _disposeAnatomy(JSObject element);

extension type _DomElement(JSObject _) implements JSObject {
  external _DomStyle get style;
}

extension type _DomStyle(JSObject _) implements JSObject {
  external set width(String value);
  external set height(String value);
  external set display(String value);
  external set overflow(String value);
  external set background(String value);
}

class AnatomyModelView extends StatefulWidget {
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
  State<AnatomyModelView> createState() => _AnatomyModelViewState();
}

class _AnatomyModelViewState extends State<AnatomyModelView> {
  JSObject? _element;
  JSFunction? _onStatus;
  JSFunction? _onError;
  String _status = '3D 모델을 불러오는 중…';
  String? _error;

  void _onElementCreated(Object element) {
    final node = element as JSObject;
    final dom = _DomElement(node);
    dom.style
      ..width = '100%'
      ..height = '100%'
      ..display = 'block'
      ..overflow = 'hidden'
      ..background = '#050a16';
    _element = node;
    _onStatus = ((JSString message) {
      final text = message.toDart;
      if (!mounted) return;
      setState(() => _status = text);
    }).toJS;
    _onError = ((JSString message) {
      final text = message.toDart;
      if (!mounted) return;
      setState(() => _error = text);
    }).toJS;
    _mount();
  }

  void _mount() {
    final element = _element;
    final onStatus = _onStatus;
    final onError = _onError;
    if (element == null || onStatus == null || onError == null) return;
    try {
      _mountAnatomy(
        element,
        widget.sourceUrl.toJS,
        widget.format.toJS,
        widget.viewMode.toJS,
        onStatus,
        onError,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '3D 뷰어를 시작하지 못했습니다. $error');
    }
  }

  @override
  void didUpdateWidget(covariant AnatomyModelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final element = _element;
    if (element == null) return;
    if (oldWidget.sourceUrl != widget.sourceUrl ||
        oldWidget.format != widget.format) {
      setState(() {
        _error = null;
        _status = '3D 모델을 불러오는 중…';
      });
      _mount();
      return;
    }
    if (oldWidget.viewMode != widget.viewMode) {
      _setAnatomyViewMode(element, widget.viewMode.toJS);
    }
  }

  @override
  void dispose() {
    final element = _element;
    if (element != null) {
      try {
        _disposeAnatomy(element);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: HtmlElementView.fromTagName(
            tagName: 'div',
            onElementCreated: _onElementCreated,
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFF07111E),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            _error ?? _status,
            style: TextStyle(
              fontSize: 11,
              color: _error == null ? Colors.white70 : const Color(0xFFFFB4AB),
            ),
          ),
        ),
      ],
    );
  }
}
