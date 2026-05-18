import 'package:flutter/material.dart';

// 非 Web 平台的空实现，不会被实际调用
class MapWebView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
