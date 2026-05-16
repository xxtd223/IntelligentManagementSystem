import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';

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
    await DioClient.delete('${ApiConstants.officeLocations}/$id');
    _load();
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(loc['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${loc['address']}\n打卡范围：${loc['allowedRadius']}米',
                          style: const TextStyle(fontSize: 12),
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
  bool _saving = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.location != null ? '编辑办公地点' : '新增办公地点',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _field(_nameCtrl, '地点名称 *'),
                const SizedBox(height: 12),
                _field(_addressCtrl, '详细地址 *'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_latCtrl, '纬度 *',
                      type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lngCtrl, '经度 *',
                      type: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                _field(_radiusCtrl, '允许打卡半径（米）',
                    type: TextInputType.number, required: false),
                const SizedBox(height: 8),
                const Text('提示：可在地图App中长按获取经纬度坐标',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
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
      validator: required ? (v) => v!.isEmpty ? '必填' : null : null,
    );
  }
}
