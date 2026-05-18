import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import 'map_picker_screen.dart';
import 'map_web_view.dart';

class OfficeLocationScreen extends StatefulWidget {
  const OfficeLocationScreen({super.key});

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  List<Map<String, dynamic>> _locations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await DioClient.get(ApiConstants.officeLocations);
      setState(() {
        _locations = (resp['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .where((e) => e['isActive'] == true)
            .toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后该地点将不再可用，是否继续？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await DioClient.delete('${ApiConstants.officeLocations}/$id');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('办公地点管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text('暂无办公地点'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length,
                  itemBuilder: (_, i) {
                    final loc = _locations[i];
                    final start = loc['workStartTime'] as String?;
                    final end = loc['workEndTime'] as String?;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(loc['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc['address'] as String,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '打卡范围：${loc['allowedRadius']}米'
                              '${start != null ? '  |  上班：$start' : ''}'
                              '${end != null ? '  下班：$end' : ''}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'edit',
                                onTap: () => _showForm(context, loc),
                                child: const Text('编辑')),
                            PopupMenuItem(
                                value: 'delete',
                                onTap: () => _delete(loc['id'] as int),
                                child: const Text('删除',
                                    style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showForm(BuildContext context, [Map<String, dynamic>? location]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LocationForm(location: location, onSaved: _load),
    );
  }
}

class _LocationForm extends StatefulWidget {
  final Map<String, dynamic>? location;
  final VoidCallback onSaved;

  const _LocationForm({this.location, required this.onSaved});

  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl =
      TextEditingController(text: widget.location?['name'] as String?);
  late final _addressCtrl =
      TextEditingController(text: widget.location?['address'] as String?);
  late final _latCtrl = TextEditingController(
      text: widget.location?['latitude']?.toString());
  late final _lngCtrl = TextEditingController(
      text: widget.location?['longitude']?.toString());
  late final _radiusCtrl = TextEditingController(
      text: (widget.location?['allowedRadius'] ?? 200).toString());
  late final _lateCtrl = TextEditingController(
      text: (widget.location?['lateThresholdMinutes'] ?? 5).toString());

  TimeOfDay? _workStart;
  TimeOfDay? _workEnd;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final startStr = widget.location?['workStartTime'] as String?;
    final endStr = widget.location?['workEndTime'] as String?;
    if (startStr != null) _workStart = _parseTime(startStr);
    if (endStr != null) _workEnd = _parseTime(endStr);
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_workStart ?? const TimeOfDay(hour: 9, minute: 0))
        : (_workEnd ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _workStart = picked;
        } else {
          _workEnd = picked;
        }
      });
    }
  }

  Future<void> _openMapPicker() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);

    // Web 端：用 HtmlElementView + amap_picker.html；移动端：用 WebView
    final mapPage = kIsWeb
        ? _WebMapPickerPage(initialLat: lat, initialLng: lng)
        : MapPickerScreen(initialLat: lat, initialLng: lng) as Widget;

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => mapPage),
    );
    if (result != null) {
      setState(() {
        _latCtrl.text = result.lat.toStringAsFixed(7);
        _lngCtrl.text = result.lng.toStringAsFixed(7);
        if (result.address.isNotEmpty && _addressCtrl.text.isEmpty) {
          _addressCtrl.text = result.address;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': double.parse(_latCtrl.text.trim()),
        'longitude': double.parse(_lngCtrl.text.trim()),
        'allowedRadius': int.parse(_radiusCtrl.text.trim()),
        if (_workStart != null) 'workStartTime': _formatTime(_workStart!),
        if (_workEnd != null) 'workEndTime': _formatTime(_workEnd!),
        'lateThresholdMinutes': int.tryParse(_lateCtrl.text.trim()) ?? 5,
        'earlyLeaveThresholdMinutes': int.tryParse(_lateCtrl.text.trim()) ?? 5,
      };

      if (widget.location != null) {
        await DioClient.put(
            '${ApiConstants.officeLocations}/${widget.location!['id']}',
            data: data);
      } else {
        await DioClient.post(ApiConstants.officeLocations, data: data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('保存失败：$e'),
              backgroundColor: AppColors.error));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖动条
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.location != null ? '编辑办公地点' : '新增办公地点',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _field(_nameCtrl, '地点名称 *'),
                const SizedBox(height: 12),
                _field(_addressCtrl, '详细地址 *'),
                const SizedBox(height: 12),

                // 坐标行 + 地图按钮
                Row(children: [
                  Expanded(
                      child: _field(_latCtrl, '纬度 *',
                          type: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _field(_lngCtrl, '经度 *',
                          type: TextInputType.number)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('地图'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                _field(_radiusCtrl, '允许打卡半径（米）',
                    type: TextInputType.number, required: false),
                const SizedBox(height: 16),

                // 办公时间
                const Text('办公时间',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _TimeTile(
                      label: '上班时间',
                      time: _workStart,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: '下班时间',
                      time: _workEnd,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _field(_lateCtrl, '迟到/早退容忍（分钟）',
                    type: TextInputType.number, required: false),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      validator: required ? (v) => v!.trim().isEmpty ? '必填' : null : null,
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeTile(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : '未设置';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(text,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: time != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Web 端地图选点页面（使用 HtmlElementView + amap_picker.html）
class _WebMapPickerPage extends StatelessWidget {
  final double? initialLat;
  final double? initialLng;

  const _WebMapPickerPage({this.initialLat, this.initialLng});

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
      body: MapWebView(
        initialLat: initialLat,
        initialLng: initialLng,
        onResult: (lat, lng, address) {
          Navigator.pop(
            context,
            LocationResult(lat: lat, lng: lng, address: address),
          );
        },
      ),
    );
  }
}
