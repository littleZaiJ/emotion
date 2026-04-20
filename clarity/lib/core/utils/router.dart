import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shell/app_shell.dart';
import '../../features/interaction/timer_page.dart';
import '../../data/repositories/settings_repository.dart';

/// 检查是否需要 Onboarding
String? _onboardingRedirect(BuildContext context, GoRouterState state) {
  final hasCompleted = SettingsRepository().hasCompletedOnboarding();
  final isOnboarding = state.matchedLocation == '/onboarding';

  if (!hasCompleted && !isOnboarding) {
    return '/onboarding';
  }
  if (hasCompleted && isOnboarding) {
    return '/dashboard';
  }
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: _onboardingRedirect,
  routes: [
    // Onboarding（独立页面，不在 Shell 内）
    GoRoute(
      path: '/onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    // 主 Shell 路由
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
        GoRoute(path: '/report', builder: (c, s) => const ReportScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      ],
    ),
    // 计时器页（独立全屏页，不在 Shell 内）
    GoRoute(path: '/timer', builder: (c, s) => const TimerPage()),
  ],
);
