import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/calendar_screen.dart';
import 'screens/admin/employee_list_screen.dart';
import 'screens/admin/office_location_screen.dart';
import 'screens/admin/work_calendar_admin_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/main_shell.dart';
import 'widgets/admin_shell.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    ShellRoute(
      builder: (_, __, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
            path: '/admin/employees',
            builder: (_, __) => const EmployeeListScreen()),
        GoRoute(
            path: '/admin/locations',
            builder: (_, __) => const OfficeLocationScreen()),
        GoRoute(
            path: '/admin/work-calendar',
            builder: (_, __) => const WorkCalendarAdminScreen()),
        GoRoute(path: '/admin/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

class AttendanceApp extends ConsumerWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '考勤打卡',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(authProvider.notifier).restoreSession();
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoggedIn) {
      context.go(auth.isAdmin ? '/admin/home' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text('考勤打卡', style: TextStyle(color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
