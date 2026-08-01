import 'package:go_router/go_router.dart';
import '../features/assistant/presentation/assistant_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AssistantScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
