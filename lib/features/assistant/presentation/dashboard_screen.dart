import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import 'widgets/dashboard_command_bar.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/live_feed_card.dart';
import 'widgets/memory_teaser_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/system_stats_row.dart';
import 'widgets/top_modules_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('JARVIS'),
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () => context.go('/settings')),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
            children: const [
              DashboardHero(),
              SizedBox(height: AppSpacing.lg),
              QuickActionsRow(),
              SizedBox(height: AppSpacing.lg),
              SystemStatsRow(),
              SizedBox(height: AppSpacing.lg),
              LiveFeedCard(),
              SizedBox(height: AppSpacing.md),
              MemoryTeaserCard(),
              SizedBox(height: AppSpacing.md),
              TopModulesCard(),
            ],
          ),
          const Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: DashboardCommandBar(),
          ),
        ],
      ),
    );
  }
}
