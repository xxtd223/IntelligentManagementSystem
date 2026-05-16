import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    extends ConsumerState<WorkCalendarAdminScreen> {
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, CalendarDay> _calendarData = {};
  int? _selectedEmployeeId;
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final resp = await DioClient.get(ApiConstants.employees,
        queryParams: {'size': 100});
    final items = resp['data']['content'] as List? ?? [];
    setState(() {
      _employees = items.map((e) => e as Map<String, dynamic>).toList();
      if (_employees.isNotEmpty) {
        _selectedEmployeeId = _employees.first['id'] as int;
        _loadCalendar();
      }
    });
  }

  Future<void> _loadCalendar() async {
    if (_selectedEmployeeId == null) return;
    final days = await ref.read(attendanceProvider.notifier).getMonthlyCalendar(
        _focusedDay.year, _focusedDay.month,
        employeeId: _selectedEmployeeId);
    setState(() {
      _calendarData = {for (final d in days) DateTime.parse(d.date): d};
    });
  }

  void _editDay(DateTime day) {
    final data = _calendarData[DateTime(day.year, day.month, day.day)];
    showDialog(
      context: context,
      builder: (_) => _DayEditDialog(
        date: day,
        existing: data,
        onSave: (entry) async {
          await DioClient.post(ApiConstants.workCalendarBatch, data: {
            'employeeId': _selectedEmployeeId,
            'entries': [entry],
          });
          _loadCalendar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('工作日历管理')),
      body: Column(
        children: [
          // 员工选择
          if (_employees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int>(
                value: _selectedEmployeeId,
                decoration: const InputDecoration(
                    labelText: '选择员工',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white),
                items: _employees
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(
                              '${e['name']} (${e['employeeNo']})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedEmployeeId = v);
                  _loadCalendar();
                },
              ),
            ),

          // 日历
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
                defaultBuilder: (context, day, focusedDay) {
                  final data = _calendarData[
                      DateTime(day.year, day.month, day.day)];
                  final isNonWork =
                      data != null && !data.isWorkDay;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: isNonWork
                        ? BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isNonWork
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _LegendDot(color: Colors.grey, label: '非工作日'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.primary, label: '工作日（点击编辑）'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}

class _DayEditDialog extends StatefulWidget {
  final DateTime date;
  final CalendarDay? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _DayEditDialog({
    required this.date,
    this.existing,
    required this.onSave,
  });

  @override
  State<_DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<_DayEditDialog> {
  late bool _isWorkDay;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isWorkDay = widget.existing?.isWorkDay ?? true;
    _noteCtrl.text = widget.existing?.note ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.date.toString().substring(0, 10)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('工作日'),
            value: _isWorkDay,
            onChanged: (v) => setState(() => _isWorkDay = v),
            activeColor: AppColors.primary,
          ),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
                labelText: '备注（如：出差、节假日）',
                border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave({
                    'date': widget.date.toString().substring(0, 10),
                    'isWorkDay': _isWorkDay,
                    'note': _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                  });
                  if (mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('保存'),
        ),
      ],
    );
  }
}
