import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/assistant/presentation/dashboard_screen.dart';
import '../../features/automation/presentation/automation_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/knowledge/presentation/knowledge_screen.dart';
import '../../features/memory/presentation/memory_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/voice/presentation/voice_screen.dart';
import '../../shared/widgets/nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Nine top-level branches, one per sidebar destination, each with its own
/// navigator so switching tabs preserves scroll position and local state —
/// [StatefulShellRoute.indexedStack] is the go_router-recommended pattern
/// for exactly this "persistent bottom/side nav" shape.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => NavShell(navigationShell: navigationShell),
        branches: [
          _branch('/', const DashboardScreen()),
          _branch('/chat', const ChatScreen()),
          _branch('/voice', const VoiceScreen()),
          _branch('/tasks', const TasksScreen()),
          _branch('/automation', const AutomationScreen()),
          _branch('/memory', const MemoryScreen()),
          _branch('/knowledge', const KnowledgeScreen()),
          _branch('/analytics', const AnalyticsScreen()),
          _branch('/settings', const SettingsScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
