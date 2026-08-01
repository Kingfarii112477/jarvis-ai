import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/orb/jarvis_orb.dart';

class DashboardHero extends ConsumerWidget {
  const DashboardHero({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up, Sir?';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkStatusProvider);
    final online = network.value == NetworkStatus.online;
    final mood = online ? AssistantMood.idle : AssistantMood.offline;

    return GlassCard(
      glowColor: AppColors.primaryGlow,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('JARVIS is standing by', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              _StatusPill(online: online),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => context.go('/voice'),
            child: JarvisOrb(mood: mood, size: 168),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            online ? 'Tap the orb to talk' : 'Offline — messages will queue',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(online ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
