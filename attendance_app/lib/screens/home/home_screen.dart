import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/ai_chat_fab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(attendanceProvider.notifier).loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(authProvider).employee;
    final attendance = ref.watch(attendanceProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问候头部
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('你好，${employee?.name ?? ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(timeStr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 今日考勤状态卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日考勤',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _AttendanceItem(
                            icon: Icons.login,
                            label: '上班打卡',
                            time: attendance.todayRecords
                                .where((r) => r.isCheckIn && r.isValid)
                                .firstOrNull
                                ?.timeDisplay,
                            isLate: attendance.todayRecords
                                .where((r) => r.isCheckIn)
                                .firstOrNull
                                ?.isLate ?? false,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 60,
                            color: AppColors.divider),
                        Expanded(
                          child: _AttendanceItem(
                            icon: Icons.logout,
                            label: '下班打卡',
                            time: attendance.todayRecords
                                .where((r) => !r.isCheckIn && r.isValid)
                                .firstOrNull
                                ?.timeDisplay,
                            isLate: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 打卡按钮
              _CheckInButton(attendance: attendance),
              const SizedBox(height: 20),

              // 办公地点信息
              if (employee?.officeLocationName != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('办公地点：${employee!.officeLocationName}',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: const AiChatFab(),
    );
  }
}

class _AttendanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? time;
  final bool isLate;

  const _AttendanceItem({
    required this.icon,
    required this.label,
    this.time,
    required this.isLate,
  });

  @override
  Widget build(BuildContext context) {
    final color = time == null
        ? AppColors.textSecondary
        : isLate
            ? AppColors.warning
            : AppColors.checkInSuccess;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          time ?? '--:--',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        if (isLate && time != null)
          const Text('迟到',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning)),
      ],
    );
  }
}

class _CheckInButton extends ConsumerWidget {
  final AttendanceState attendance;

  const _CheckInButton({required this.attendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canCheckIn = !attendance.hasCheckIn;
    final bool canCheckOut = attendance.hasCheckIn && !attendance.hasCheckOut;

    Future<void> doCheckIn(String type) async {
      try {
        final result = await ref.read(attendanceProvider.notifier).checkIn(type);
        if (!context.mounted) return;
        final status = result['status'] as String? ?? 'NORMAL';
        String msg = type == 'CHECK_IN' ? '上班打卡成功' : '下班打卡成功';
        if (status == 'LATE') msg += '（迟到）';
        if (status == 'EARLY_LEAVE') msg += '（早退）';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.checkInSuccess));
      } catch (e) {
        if (!context.mounted) return;
        final msg = e is DioException
            ? (e.message ?? '打卡失败，请重试')
            : e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canCheckIn ? () => doCheckIn('CHECK_IN') : null,
            icon: const Icon(Icons.login),
            label: const Text('上班打卡', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  canCheckIn ? AppColors.checkInSuccess : Colors.grey[300],
              foregroundColor: canCheckIn ? Colors.white : AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canCheckOut ? () => doCheckIn('CHECK_OUT') : null,
            icon: const Icon(Icons.logout),
            label: const Text('下班打卡', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  canCheckOut ? AppColors.primary : Colors.grey[300],
              foregroundColor:
                  canCheckOut ? Colors.white : AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
