import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../automation/presentation/automation_providers.dart';

class TopModulesCard extends ConsumerWidget {
  const TopModulesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflows = ref.watch(workflowsProvider).take(5).toList();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Automation modules',
            icon: Icons.widgets_outlined,
            action: TextButton(onPressed: () => context.go('/automation'), child: const Text('Manage')),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (workflows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No workflows registered yet.', style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            ...workflows.map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 15, color: w.active ? AppColors.primaryGlow : AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(w.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Text(
                      w.active ? 'Active' : 'Paused',
                      style: TextStyle(color: w.active ? AppColors.success : AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
