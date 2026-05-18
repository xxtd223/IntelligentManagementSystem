import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../services/reminder_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = ['/home', '/calendar', '/profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.person_outline
  ];
  static const _activeIcons = [
    Icons.home,
    Icons.calendar_month,
    Icons.person
  ];
  static const _labels = ['首页', '日历', '我的'];

  @override
  void initState() {
    super.initState();
    ReminderService.init(ref);
  }

  @override
  void dispose() {
    ReminderService.dispose();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: widget.child,
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
