import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../dashboard_providers.dart';

/// The floating glass input pinned to the bottom of the dashboard —
/// typing here and hitting send hands off straight to a fresh Chat
/// session via [chatDraftProvider].
///
/// Uses the heavy (`BackdropFilter`) blur variant only when the user has
/// opted in under Settings → Animations; it sits over scrolling content,
/// which is exactly the configuration that triggered the framebuffer bug
/// documented on [GlassCard], so the safe flat-tint card is the default.
class DashboardCommandBar extends ConsumerStatefulWidget {
  const DashboardCommandBar({super.key});

  @override
  ConsumerState<DashboardCommandBar> createState() => _DashboardCommandBarState();
}

class _DashboardCommandBarState extends ConsumerState<DashboardCommandBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatDraftProvider.notifier).state = _controller.text.trim();
    _controller.clear();
    context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    final heavyBlur = ref.watch(appSettingsProvider).heavyBlurEnabled;
    final radius = BorderRadius.circular(AppRadius.pill);
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs);

    return heavyBlur
        ? GlassCard.blurred(borderRadius: radius, padding: padding, child: _content())
        : GlassCard(strong: true, borderRadius: radius, padding: padding, child: _content());
  }

  Widget _content() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.graphic_eq_rounded, color: AppColors.secondaryGlow),
          onPressed: () => context.go('/voice'),
          tooltip: 'Voice',
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Ask me anything…', border: InputBorder.none, isCollapsed: true),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome, color: AppColors.primaryGlow),
          onPressed: () => context.go('/voice'),
          tooltip: 'JARVIS',
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.textPrimary),
          onPressed: _submit,
        ),
      ],
    );
  }
}
