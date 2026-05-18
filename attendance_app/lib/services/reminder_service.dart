import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/chat_provider.dart';

class ReminderService {
  static Timer? _timer;
  static String? _workStartTime; // "09:00"
  static String? _workEndTime;   // "18:00"

  static void init(WidgetRef ref) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick(ref));
    Future.delayed(const Duration(seconds: 3), () => _tick(ref));
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _workStartTime = null;
    _workEndTime = null;
  }

  static Future<void> _tick(WidgetRef ref) async {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.isAdmin) return;

      final employee = auth.employee;
      final locationId = employee?.officeLocationId;
      if (locationId == null) return;

      // 懒加载工作时间
      if (_workStartTime == null) {
        await _loadWorkTimes(locationId);
      }
      if (_workStartTime == null) return;

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final todayKey = 'reminder_${now.year}_${now.month}_${now.day}';
      final sentFlags = prefs.getStringList(todayKey) ?? [];

      final attendance = ref.read(attendanceProvider);

      // 上班前15分钟提醒
      if (!sentFlags.contains('check_in')) {
        final workStart = _parseTime(_workStartTime!);
        final remindAt = workStart.subtract(const Duration(minutes: 15));
        final remindEnd = workStart.add(const Duration(minutes: 30));
        if (now.isAfter(remindAt) &&
            now.isBefore(remindEnd) &&
            !attendance.hasCheckIn) {
          final minLeft = workStart.difference(now).inMinutes;
          final msg = minLeft > 0
              ? '⏰ 上班提醒：距上班时间还有 $minLeft 分钟，请记得打卡！\n你可以说「帮我上班打卡」完成打卡。'
              : '⏰ 上班时间到了，你还没有打卡，快来打卡吧！\n你可以说「帮我上班打卡」完成打卡。';
          ref.read(chatProvider.notifier).addReminderMessage(msg);
          sentFlags.add('check_in');
          await prefs.setStringList(todayKey, sentFlags);
        }
      }

      // 下班前10分钟提醒
      if (!sentFlags.contains('check_out') && attendance.hasCheckIn) {
        final workEnd = _parseTime(_workEndTime!);
        final remindAt = workEnd.subtract(const Duration(minutes: 10));
        final remindEnd = workEnd.add(const Duration(minutes: 30));
        if (now.isAfter(remindAt) &&
            now.isBefore(remindEnd) &&
            !attendance.hasCheckOut) {
          final minLeft = workEnd.difference(now).inMinutes;
          final msg = minLeft > 0
              ? '⏰ 下班提醒：距下班时间还有 $minLeft 分钟，别忘了打下班卡！\n你可以说「帮我下班打卡」完成打卡。'
              : '⏰ 下班时间到了，你还没打下班卡，快来打卡吧！\n你可以说「帮我下班打卡」完成打卡。';
          ref.read(chatProvider.notifier).addReminderMessage(msg);
          sentFlags.add('check_out');
          await prefs.setStringList(todayKey, sentFlags);
        }
      }
    } catch (_) {}
  }

  static Future<void> _loadWorkTimes(int locationId) async {
    try {
      final resp =
          await DioClient.get('${ApiConstants.officeLocations}/$locationId');
      final data = resp['data'] as Map<String, dynamic>;
      _workStartTime = data['workStartTime'] as String?;
      _workEndTime = data['workEndTime'] as String?;
    } catch (_) {}
  }

  static DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
