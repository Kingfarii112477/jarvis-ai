import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../memory/presentation/memory_providers.dart';

class MemoryTeaserCard extends ConsumerWidget {
  const MemoryTeaserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider);

    return GlassCard(
      glowColor: AppColors.accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: () => context.go('/memory'),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: 0.5), AppColors.accent.withValues(alpha: 0.05)]),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Memory core', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('${memories.length} total memories', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
