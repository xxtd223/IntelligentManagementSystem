import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(authProvider).employee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('个人信息')),
      body: employee == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 头像和名字
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            employee.name.substring(0, 1),
                            style: const TextStyle(
                                fontSize: 32,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(employee.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: employee.isAdmin
                                ? AppColors.warning.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            employee.isAdmin ? '管理员' : '员工',
                            style: TextStyle(
                                color: employee.isAdmin
                                    ? AppColors.warning
                                    : AppColors.primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 员工信息
                  _InfoCard(
                    items: [
                      _InfoItem('员工编号', employee.employeeNo),
                      _InfoItem('所属部门', employee.departmentName ?? '未分配'),
                      _InfoItem('办公地点', employee.officeLocationName ?? '未分配'),
                      if (employee.phone != null)
                        _InfoItem('联系电话', employee.phone!),
                      if (employee.email != null)
                        _InfoItem('邮箱', employee.email!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('确认退出'),
                            content: const Text('确定要退出登录吗？'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消')),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('退出',
                                      style:
                                          TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('退出登录',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                  width: 80,
                  child: Text(items[i].label,
                      style: const TextStyle(color: AppColors.textSecondary))),
              Expanded(
                  child: Text(items[i].value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary))),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}
