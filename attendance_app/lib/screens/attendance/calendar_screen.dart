import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../models/calendar_day.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/ai_chat_fab.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, CalendarDay> _calendarData = {};
  Map<String, dynamic>? _summary;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _loading = true);
    try {
      final days = await ref
          .read(attendanceProvider.notifier)
          .getMonthlyCalendar(month.year, month.month);
      final summary = await ref
          .read(attendanceProvider.notifier)
          .getMonthlySummary(month.year, month.month);
      setState(() {
        _calendarData = {
          for (final d in days)
            DateTime.parse(d.date): d
        };
        _summary = summary;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  CalendarDay? _dayData(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _calendarData[key];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay != null ? _dayData(_selectedDay!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('考勤日历')),
      body: Column(
        children: [
          // 统计卡片
          if (_summary != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem('正常', '${_summary!['normalCount']}天',
                      AppColors.checkInSuccess),
                  _SummaryItem(
                      '迟到', '${_summary!['lateCount']}次', AppColors.warning),
                  _SummaryItem('早退', '${_summary!['earlyLeaveCount']}次',
                      AppColors.primary),
                  _SummaryItem('缺卡', '${_summary!['missingCount']}天',
                      AppColors.error),
                ],
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
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) =>
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  }),
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadMonth(focused);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final data = _dayData(day);
                  if (data == null || !data.isWorkDay) return null;
                  final color = data.isMissing
                      ? AppColors.checkInMissing
                      : data.isLate
                          ? AppColors.warning
                          : data.hasCheckIn && data.hasCheckOut
                              ? AppColors.checkInSuccess
                              : AppColors.textSecondary;
                  return Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                  );
                },
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
              ),
            ),
          ),

          // 选中日期详情
          if (selected != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedDay.toString().substring(0, 10),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (!selected.isWorkDay)
                    const Text('休息日',
                        style: TextStyle(color: AppColors.textSecondary))
                  else ...[
                    _DayDetailRow(
                      label: '上班打卡',
                      time: selected.checkInTimeDisplay,
                      status: selected.checkInStatus,
                    ),
                    const SizedBox(height: 8),
                    _DayDetailRow(
                      label: '下班打卡',
                      time: selected.checkOutTimeDisplay,
                      status: selected.checkOutStatus,
                    ),
                    if (selected.note != null) ...[
                      const SizedBox(height: 8),
                      Text('备注：${selected.note}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  ],
                ],
              ),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: const AiChatFab(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}

class _DayDetailRow extends StatelessWidget {
  final String label;
  final String time;
  final String? status;

  const _DayDetailRow(
      {required this.label, required this.time, this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status == null
        ? AppColors.textSecondary
        : status == 'LATE' || status == 'EARLY_LEAVE'
            ? AppColors.warning
            : status == 'OUTSIDE_RANGE' || status == 'INVALID'
                ? AppColors.error
                : AppColors.checkInSuccess;

    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary))),
        Text(time,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: time == '--:--'
                    ? AppColors.textSecondary
                    : statusColor)),
        if (status != null && status != 'NORMAL') ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_statusLabel(status!),
                style: TextStyle(fontSize: 11, color: statusColor)),
          ),
        ],
      ],
    );
  }

  String _statusLabel(String s) => switch (s) {
        'LATE' => '迟到',
        'EARLY_LEAVE' => '早退',
        'OUTSIDE_RANGE' => '范围外',
        'INVALID' => '无效',
        _ => s,
      };
}
