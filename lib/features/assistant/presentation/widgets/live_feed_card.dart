import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../../../analytics/domain/usage_event.dart';

(IconData, String, Color) _describe(UsageEventType type) => switch (type) {
      UsageEventType.chatMessage => (Icons.chat_bubble_outline_rounded, 'Chat message sent', AppColors.primaryGlow),
      UsageEventType.voiceInteraction => (Icons.graphic_eq_rounded, 'Voice interaction', AppColors.secondaryGlow),
      UsageEventType.automationRun => (Icons.bolt_rounded, 'Automation triggered', AppColors.warning),
      UsageEventType.taskCompleted => (Icons.check_circle_outline_rounded, 'Task completed', AppColors.success),
      UsageEventType.knowledgeUpload => (Icons.upload_file_rounded, 'Document indexed', AppColors.accent),
      UsageEventType.memorySaved => (Icons.psychology_outlined, 'Memory saved', AppColors.accent),
    };

class LiveFeedCard extends ConsumerWidget {
  const LiveFeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(analyticsRepositoryProvider).getEvents().reversed.take(6).toList();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Live feed',
            icon: Icons.podcasts_rounded,
            action: TextButton(onPressed: () => context.go('/analytics'), child: const Text('View all')),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No activity yet — start a chat or run a workflow.', style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            ...events.map((event) {
              final (icon, label, color) = _describe(event.type);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5))),
                    Text(DateFormat.Hms().format(event.timestamp), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
