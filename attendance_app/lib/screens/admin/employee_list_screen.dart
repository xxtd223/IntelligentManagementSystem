import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../models/employee.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  List<Employee> _employees = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? keyword}) async {
    setState(() => _loading = true);
    try {
      final resp = await DioClient.get(ApiConstants.employees,
          queryParams: {if (keyword != null) 'keyword': keyword});
      final content = (resp['data']['content'] as List? ?? resp['data'] as List? ?? []);
      setState(() {
        _employees = content
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(Employee emp) async {
    final newStatus = emp.isActive ? 'INACTIVE' : 'ACTIVE';
    await DioClient.patch('${ApiConstants.employees}/${emp.id}/status',
        data: {'status': newStatus});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('员工管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEmployeeForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索姓名或员工编号',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        })
                    : null,
              ),
              onChanged: (v) => _load(keyword: v.isEmpty ? null : v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? const Center(child: Text('暂无员工数据'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _employees.length,
                        itemBuilder: (_, i) => _EmployeeTile(
                          employee: _employees[i],
                          onToggleStatus: () => _toggleStatus(_employees[i]),
                          onEdit: () => _showEmployeeForm(context, _employees[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeForm(BuildContext context, [Employee? employee]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmployeeForm(
        employee: employee,
        onSaved: _load,
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final Employee employee;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;

  const _EmployeeTile({
    required this.employee,
    required this.onToggleStatus,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: employee.isAdmin
              ? AppColors.warning.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.1),
          child: Text(employee.name.substring(0, 1),
              style: TextStyle(
                  color: employee.isAdmin ? AppColors.warning : AppColors.primary,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(employee.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${employee.employeeNo}  ·  ${employee.departmentName ?? '未分配部门'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: employee.isActive
                    ? AppColors.checkInSuccess.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(employee.isActive ? '在职' : '离职',
                  style: TextStyle(
                      fontSize: 11,
                      color: employee.isActive
                          ? AppColors.checkInSuccess
                          : AppColors.error)),
            ),
            PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: const Text('编辑'),
                    onTap: onEdit),
                PopupMenuItem(
                  value: 'toggle',
                  onTap: onToggleStatus,
                  child: Text(employee.isActive ? '停用' : '启用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeForm extends StatefulWidget {
  final Employee? employee;
  final VoidCallback onSaved;

  const _EmployeeForm({this.employee, required this.onSaved});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _noCtrl = TextEditingController(text: widget.employee?.employeeNo);
  late final _nameCtrl = TextEditingController(text: widget.employee?.name);
  late final _phoneCtrl = TextEditingController(text: widget.employee?.phone);
  late final _emailCtrl = TextEditingController(text: widget.employee?.email);
  final _pwCtrl = TextEditingController();
  String _role = 'EMPLOYEE';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _role = widget.employee?.role ?? 'EMPLOYEE';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'employeeNo': _noCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _role,
        if (_pwCtrl.text.isNotEmpty) 'password': _pwCtrl.text,
        if (widget.employee == null) 'password': _pwCtrl.text,
      };
      if (widget.employee != null) {
        await DioClient.put(
            '${ApiConstants.employees}/${widget.employee!.id}', data: data);
      } else {
        await DioClient.post(ApiConstants.employees, data: data);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.employee != null ? '编辑员工' : '新增员工',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _noCtrl,
                  decoration: const InputDecoration(
                      labelText: '员工编号 *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? '必填' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: '姓名 *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? '必填' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: '联系电话', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: '邮箱', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.employee != null ? '新密码（不改则留空）' : '初始密码 *',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      widget.employee == null && (v == null || v.isEmpty)
                          ? '必填'
                          : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                      labelText: '角色', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'EMPLOYEE', child: Text('普通员工')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('管理员')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 24),
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
}
