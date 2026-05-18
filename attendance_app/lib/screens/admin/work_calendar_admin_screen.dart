import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../models/calendar_day.dart';
import '../../providers/attendance_provider.dart';

class WorkCalendarAdminScreen extends ConsumerStatefulWidget {
  const WorkCalendarAdminScreen({super.key});

  @override
  ConsumerState<WorkCalendarAdminScreen> createState() =>
      _WorkCalendarAdminScreenState();
}

class _WorkCalendarAdminScreenState
    extends ConsumerState<WorkCalendarAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadLocations();
    _loadEmployees();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    final resp = await DioClient.get(ApiConstants.officeLocations);
    final items = (resp['data'] as List)
        .map((e) => e as Map<String, dynamic>)
        .where((e) => e['isActive'] == true)
        .toList();
    if (mounted) setState(() => _locations = items);
  }

  Future<void> _loadEmployees() async {
    final resp =
        await DioClient.get(ApiConstants.employees, queryParams: {'size': 100});
    final items = resp['data']['content'] as List? ?? [];
    if (mounted) {
      setState(() {
        _employees = items.map((e) => e as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('工作日历管理'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.location_on_outlined), text: '按地点设置'),
            Tab(icon: Icon(Icons.person_outline), text: '员工考勤'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LocationCalendarTab(locations: _locations),
          _EmployeeAttendanceTab(employees: _employees),
        ],
      ),
    );
  }
}

// ─── Tab 1: 按地点批量设置工作日历 ─────────────────────────────────────────────

class _LocationCalendarTab extends StatefulWidget {
  final List<Map<String, dynamic>> locations;

  const _LocationCalendarTab({required this.locations});

  @override
  State<_LocationCalendarTab> createState() => _LocationCalendarTabState();
}

class _LocationCalendarTabState extends State<_LocationCalendarTab> {
  int? _selectedLocationId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LocationCalendarTab old) {
    super.didUpdateWidget(old);
    if (widget.locations.isNotEmpty && _selectedLocationId == null) {
      _selectedLocationId = widget.locations.first['id'] as int;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.locations.isNotEmpty) {
      _selectedLocationId = widget.locations.first['id'] as int;
    }
  }

  String _rangeLabel() {
    if (_rangeStart == null) return '请在日历上点击选择起始日期';
    final fmt = DateFormat('MM月dd日');
    if (_rangeEnd == null) return '起始：${fmt.format(_rangeStart!)}  （再点击结束日期）';
    return '${fmt.format(_rangeStart!)}  →  ${fmt.format(_rangeEnd!)}';
  }

  Future<void> _apply(bool isWorkDay) async {
    if (_selectedLocationId == null || _rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择地点和日期范围')));
      return;
    }
    setState(() => _saving = true);
    try {
      await DioClient.post(ApiConstants.workCalendarLocationBatch, data: {
        'locationId': _selectedLocationId,
        'startDate': _rangeStart!.toString().substring(0, 10),
        'endDate': _rangeEnd!.toString().substring(0, 10),
        'isWorkDay': isWorkDay,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      });
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _noteCtrl.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('已将所选日期设为${isWorkDay ? "工作日" : "非工作日"}，'
                  '应用至该地点所有员工'),
              backgroundColor: AppColors.checkInSuccess));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 地点选择
          if (widget.locations.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                  labelText: '选择办公地点',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white),
              items: widget.locations
                  .map((e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text(e['name'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLocationId = v),
            )
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('暂无办公地点，请先添加'),
              ),
            ),
          const SizedBox(height: 16),

          // 日历
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              rangeSelectionMode: RangeSelectionMode.enforced,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: AppColors.primary.withOpacity(0.15),
                rangeStartDecoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                withinRangeDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.rectangle),
                todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle),
              ),
              headerStyle:
                  const HeaderStyle(formatButtonVisible: false),
            ),
          ),
          const SizedBox(height: 12),

          // 已选范围显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_rangeLabel(),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
                if (_rangeStart != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () =>
                        setState(() {
                          _rangeStart = null;
                          _rangeEnd = null;
                        }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '备注（如：国庆假期）',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_saving || _rangeStart == null || _rangeEnd == null)
                      ? null
                      : () => _apply(true),
                  icon: const Icon(Icons.work_outlined),
                  label: const Text('设为工作日'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.checkInSuccess,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_saving || _rangeStart == null || _rangeEnd == null)
                      ? null
                      : () => _apply(false),
                  icon: const Icon(Icons.weekend_outlined),
                  label: const Text('设为非工作日'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '说明：此操作会批量修改该地点下所有在职员工的工作日历',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: 查看/编辑员工考勤 ─────────────────────────────────────────────────

class _EmployeeAttendanceTab extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> employees;

  const _EmployeeAttendanceTab({required this.employees});

  @override
  ConsumerState<_EmployeeAttendanceTab> createState() =>
      _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState
    extends ConsumerState<_EmployeeAttendanceTab> {
  int? _selectedEmployeeId;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, CalendarDay> _calendarData = {};

  @override
  void initState() {
    super.initState();
    if (widget.employees.isNotEmpty) {
      _selectedEmployeeId = widget.employees.first['id'] as int;
      _loadCalendar();
    }
  }

  Future<void> _loadCalendar() async {
    if (_selectedEmployeeId == null) return;
    final days = await ref
        .read(attendanceProvider.notifier)
        .getMonthlyCalendar(_focusedDay.year, _focusedDay.month,
            employeeId: _selectedEmployeeId);
    if (mounted) {
      setState(() {
        _calendarData = {
          for (final d in days) DateTime.parse(d.date): d
        };
      });
    }
  }

  void _editDay(DateTime day) async {
    final data = _calendarData[DateTime(day.year, day.month, day.day)];
    await showDialog(
      context: context,
      builder: (_) => _AttendanceEditDialog(
        date: day,
        existing: data,
        employeeId: _selectedEmployeeId!,
        onChanged: _loadCalendar,
      ),
    );
  }

  Color _dayColor(CalendarDay? data) {
    if (data == null) return Colors.transparent;
    if (!data.isWorkDay) return Colors.grey[200]!;
    if (data.isMissing) return AppColors.error.withOpacity(0.15);
    if (data.isLate) return AppColors.warning.withOpacity(0.2);
    if (data.hasCheckIn && data.hasCheckOut) return AppColors.checkInSuccess.withOpacity(0.15);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 员工选择
        if (widget.employees.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _selectedEmployeeId,
              decoration: const InputDecoration(
                  labelText: '选择员工',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white),
              items: widget.employees
                  .map((e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child:
                            Text('${e['name']} (${e['employeeNo']})'),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedEmployeeId = v);
                _loadCalendar();
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无员工'),
          ),

        // 日历
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    onDaySelected: (selected, focused) {
                      setState(() => _focusedDay = focused);
                      _editDay(selected);
                    },
                    onPageChanged: (focused) {
                      _focusedDay = focused;
                      _loadCalendar();
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focused) {
                        final d = _calendarData[
                            DateTime(day.year, day.month, day.day)];
                        final bg = _dayColor(d);
                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: bg == Colors.transparent
                              ? null
                              : BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(6)),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${day.day}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: d != null && !d.isWorkDay
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary)),
                                if (d != null && d.isWorkDay) ...[
                                  if (d.hasCheckIn)
                                    const Icon(Icons.login,
                                        size: 8,
                                        color: AppColors.checkInSuccess),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    headerStyle:
                        const HeaderStyle(formatButtonVisible: false),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 16,
                    children: [
                      _LegendDot(
                          color: AppColors.checkInSuccess.withOpacity(0.4),
                          label: '正常出勤'),
                      _LegendDot(
                          color: AppColors.warning.withOpacity(0.4),
                          label: '迟到'),
                      _LegendDot(
                          color: AppColors.error.withOpacity(0.3),
                          label: '缺勤'),
                      _LegendDot(
                          color: Colors.grey[200]!,
                          label: '非工作日'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('点击日期可查看或修改该员工当天的考勤记录',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 考勤记录编辑对话框 ────────────────────────────────────────────────────────

class _AttendanceEditDialog extends StatefulWidget {
  final DateTime date;
  final CalendarDay? existing;
  final int employeeId;
  final VoidCallback onChanged;

  const _AttendanceEditDialog({
    required this.date,
    required this.existing,
    required this.employeeId,
    required this.onChanged,
  });

  @override
  State<_AttendanceEditDialog> createState() => _AttendanceEditDialogState();
}

class _AttendanceEditDialogState extends State<_AttendanceEditDialog> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dateStr = widget.date.toString().substring(0, 10);
      final resp = await DioClient.get(ApiConstants.attendanceRecords,
          queryParams: {
            'employeeId': widget.employeeId,
            'startDate': dateStr,
            'endDate': dateStr,
          });
      setState(() {
        _records = (resp['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addRecord(String checkType) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: checkType == 'CHECK_IN'
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 18, minute: 0),
      helpText: checkType == 'CHECK_IN' ? '选择上班时间' : '选择下班时间',
    );
    if (picked == null || !mounted) return;

    final dateStr = widget.date.toString().substring(0, 10);
    final timeStr =
        '$dateStr T${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';

    await DioClient.post(ApiConstants.attendanceManual, data: {
      'employeeId': widget.employeeId,
      'checkTime': timeStr,
      'checkType': checkType,
      'note': '管理员手动录入',
    });
    await _load();
    widget.onChanged();
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    final checkTimeStr = record['checkTime'] as String;
    final dt = DateTime.parse(checkTimeStr);
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
    );
    if (picked == null || !mounted) return;

    final dateStr = widget.date.toString().substring(0, 10);
    final newTimeStr =
        '${dateStr}T${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    await DioClient.put(
        '/attendance/${record['id']}',
        data: {'checkTime': newTimeStr});
    await _load();
    widget.onChanged();
  }

  Future<void> _invalidate(Map<String, dynamic> record) async {
    await DioClient.put(
        '/attendance/${record['id']}',
        data: {'isValid': false, 'note': '管理员作废'});
    await _load();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('yyyy年MM月dd日').format(widget.date);
    final hasCheckIn =
        _records.any((r) => r['checkType'] == 'CHECK_IN' && r['isValid'] == true);
    final hasCheckOut =
        _records.any((r) => r['checkType'] == 'CHECK_OUT' && r['isValid'] == true);

    return AlertDialog(
      title: Text(dateLabel),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_records.isEmpty)
                    const Text('当天暂无考勤记录',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ..._records.map((r) => _RecordTile(
                          record: r,
                          onEdit: () => _editRecord(r),
                          onInvalidate: r['isValid'] == true
                              ? () => _invalidate(r)
                              : null,
                        )),
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (!hasCheckIn)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addRecord('CHECK_IN'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('补上班'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.checkInSuccess),
                          ),
                        ),
                      if (!hasCheckIn && !hasCheckOut)
                        const SizedBox(width: 8),
                      if (!hasCheckOut)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addRecord('CHECK_OUT'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('补下班'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭')),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onEdit;
  final VoidCallback? onInvalidate;

  const _RecordTile(
      {required this.record, required this.onEdit, this.onInvalidate});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = record['checkType'] == 'CHECK_IN';
    final isValid = record['isValid'] == true;
    final checkTimeStr = record['checkTime'] as String;
    final dt = DateTime.parse(checkTimeStr);
    final timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final status = record['status'] as String? ?? 'NORMAL';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCheckIn ? Icons.login : Icons.logout,
        color: isValid ? AppColors.primary : Colors.grey,
        size: 20,
      ),
      title: Text(
        '${isCheckIn ? "上班" : "下班"}打卡  $timeLabel',
        style: TextStyle(
            fontSize: 14,
            decoration: isValid ? null : TextDecoration.lineThrough,
            color: isValid ? AppColors.textPrimary : Colors.grey),
      ),
      subtitle: Text(
        _statusLabel(status) + (isValid ? '' : '  [已作废]'),
        style: TextStyle(
            fontSize: 11,
            color: _statusColor(status, isValid)),
      ),
      trailing: isValid
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: '修改时间'),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18,
                        color: AppColors.error),
                    onPressed: onInvalidate,
                    tooltip: '作废'),
              ],
            )
          : null,
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'LATE': return '迟到';
      case 'EARLY_LEAVE': return '早退';
      case 'OUTSIDE_RANGE': return '超范围';
      default: return '正常';
    }
  }

  Color _statusColor(String s, bool isValid) {
    if (!isValid) return Colors.grey;
    switch (s) {
      case 'LATE': return AppColors.warning;
      case 'EARLY_LEAVE': return AppColors.warning;
      case 'OUTSIDE_RANGE': return AppColors.error;
      default: return AppColors.checkInSuccess;
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}
