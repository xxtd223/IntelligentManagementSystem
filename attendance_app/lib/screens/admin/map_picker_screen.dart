import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String address;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat ?? 39.909187;
    final lng = widget.initialLng ?? 116.397451;

    _controller = WebViewController();
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }
    _controller
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..addJavaScriptChannel(
        'MapChannel',
        onMessageReceived: (msg) {
          final data = json.decode(msg.message) as Map<String, dynamic>;
          if (!mounted) return;
          Navigator.pop(
            context,
            LocationResult(
              lat: (data['lat'] as num).toDouble(),
              lng: (data['lng'] as num).toDouble(),
              address: (data['address'] as String?) ?? '',
            ),
          );
        },
      )
      ..loadHtmlString(_buildHtml(lat, lng), baseUrl: 'https://m.amap.com');
  }

  String _buildHtml(double lat, double lng) {
    final key = ApiConstants.amapWebKey;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body { width:100%; height:100%; overflow:hidden; font-family:sans-serif; }
    #map-container { width:100%; height:100vh; }
    #info-bar {
      position:absolute; bottom:64px; left:12px; right:12px;
      background:#fff; padding:12px 16px; border-radius:12px;
      box-shadow:0 2px 12px rgba(0,0,0,.15); font-size:14px;
    }
    #address-text { color:#333; line-height:1.5; }
    #coord-text { color:#888; font-size:12px; margin-top:4px; }
    #confirm-btn {
      position:absolute; bottom:10px; left:12px; right:12px;
      background:#2979FF; color:#fff; border:none; padding:14px;
      border-radius:12px; font-size:16px; font-weight:600; cursor:pointer;
      box-shadow:0 4px 12px rgba(41,121,255,.4);
    }
  </style>
</head>
<body>
  <div id="map-container"></div>
  <div id="info-bar">
    <div id="address-text">点击地图或拖动标记选择位置</div>
    <div id="coord-text"></div>
  </div>
  <button id="confirm-btn" onclick="confirmSel()">确认选择此位置</button>
  <script src="https://webapi.amap.com/maps?v=2.0&key=$key&plugin=AMap.Geocoder"></script>
  <script>
    var selLat=$lat, selLng=$lng, selAddr='';
    var map = new AMap.Map('map-container',{zoom:16,center:[$lng,$lat]});
    var geocoder = new AMap.Geocoder({radius:300});
    var marker = new AMap.Marker({position:[$lng,$lat],draggable:true,animation:'AMAP_ANIMATION_DROP'});
    map.add(marker);

    function revGeo(lng,lat){
      selLat=lat; selLng=lng;
      geocoder.getAddress([lng,lat],function(st,res){
        if(st==='complete'&&res.regeocode){
          selAddr=res.regeocode.formattedAddress;
          document.getElementById('address-text').innerText=selAddr;
        }
        document.getElementById('coord-text').innerText=
          '纬度: '+lat.toFixed(6)+'  经度: '+lng.toFixed(6);
      });
    }

    marker.on('dragend',function(e){revGeo(e.lnglat.getLng(),e.lnglat.getLat());});
    map.on('click',function(e){marker.setPosition(e.lnglat);revGeo(e.lnglat.getLng(),e.lnglat.getLat());});
    revGeo($lng,$lat);

    function confirmSel(){
      MapChannel.postMessage(JSON.stringify({lat:selLat,lng:selLng,address:selAddr}));
    }
  </script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图选点'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
