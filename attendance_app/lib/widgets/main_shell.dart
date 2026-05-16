import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = ['/home', '/calendar', '/profile'];
  static const _icons = [Icons.home_outlined, Icons.calendar_month_outlined,
      Icons.person_outline];
  static const _activeIcons = [Icons.home, Icons.calendar_month, Icons.person];
  static const _labels = ['首页', '日历', '我的'];

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
