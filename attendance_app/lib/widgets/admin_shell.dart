import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  static const _tabs = ['/admin/home', '/admin/employees',
      '/admin/locations', '/admin/work-calendar', '/admin/profile'];
  static const _icons = [
    Icons.dashboard_outlined, Icons.people_outline,
    Icons.location_on_outlined, Icons.event_note_outlined, Icons.person_outline
  ];
  static const _activeIcons = [
    Icons.dashboard, Icons.people,
    Icons.location_on, Icons.event_note, Icons.person
  ];
  static const _labels = ['总览', '员工', '地点', '日历', '我的'];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: List.generate(
          _tabs.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i], color: AppColors.primary),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
