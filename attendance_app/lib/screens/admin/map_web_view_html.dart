// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';

class MapWebView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng, String address) onResult;

  const MapWebView({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onResult,
  });

  @override
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  late final String _viewId;
  html.EventListener? _listener;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat ?? 39.909187;
    final lng = widget.initialLng ?? 116.397451;
    const key = ApiConstants.amapWebKey;
    _viewId = 'amap-picker-${DateTime.now().millisecondsSinceEpoch}';

    const secCode = ApiConstants.amapSecurityCode;
    final secParam = secCode.isNotEmpty ? '&securityCode=$secCode' : '';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      return html.IFrameElement()
        ..src = 'amap_picker.html?lat=$lat&lng=$lng&key=$key$secParam'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
    });

    _listener = (html.Event e) {
      if (e is html.MessageEvent) {
        try {
          final data = json.decode(e.data as String) as Map<String, dynamic>;
          if (data['type'] == 'amap_result' && mounted) {
            widget.onResult(
              (data['lat'] as num).toDouble(),
              (data['lng'] as num).toDouble(),
              (data['address'] as String?) ?? '',
            );
          }
        } catch (_) {}
      }
    };
    html.window.addEventListener('message', _listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      html.window.removeEventListener('message', _listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
