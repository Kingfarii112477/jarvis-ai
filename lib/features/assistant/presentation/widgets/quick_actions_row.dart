import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/quick_action_chip.dart';
import '../dashboard_providers.dart';

class _QuickAction {
  const _QuickAction({required this.icon, required this.label, required this.color, this.route, this.draft});
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  final String? draft;
}

const _actions = [
  _QuickAction(icon: Icons.graphic_eq_rounded, label: 'Voice', color: AppColors.secondaryGlow, route: '/voice'),
  _QuickAction(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', color: AppColors.primaryGlow, route: '/chat'),
  _QuickAction(icon: Icons.image_outlined, label: 'Image', color: AppColors.accent, draft: 'Generate an image of '),
  _QuickAction(icon: Icons.code_rounded, label: 'Code', color: AppColors.success, draft: 'Write code that '),
  _QuickAction(icon: Icons.travel_explore_outlined, label: 'Research', color: AppColors.primaryGlow, draft: 'Research and summarize '),
  _QuickAction(icon: Icons.bolt_outlined, label: 'Automation', color: AppColors.warning, route: '/automation'),
  _QuickAction(icon: Icons.mail_outline_rounded, label: 'Email', color: AppColors.secondaryGlow, draft: 'Draft an email about '),
  _QuickAction(icon: Icons.picture_as_pdf_outlined, label: 'PDF', color: AppColors.error, route: '/knowledge'),
  _QuickAction(icon: Icons.smart_display_outlined, label: 'YouTube', color: AppColors.error, draft: 'Summarize this YouTube video: '),
  _QuickAction(icon: Icons.psychology_outlined, label: 'Memory', color: AppColors.accent, route: '/memory'),
];

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (context, i) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return QuickActionChip(
            icon: action.icon,
            label: action.label,
            color: action.color,
            onTap: () {
              if (action.route != null) {
                context.go(action.route!);
              } else if (action.draft != null) {
                ref.read(chatDraftProvider.notifier).state = action.draft;
                context.go('/chat');
              }
            },
          );
        },
      ),
    );
  }
}
