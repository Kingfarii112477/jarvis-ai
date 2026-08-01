import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glow_button.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.onSend, required this.isSending, this.initialText});

  final ValueChanged<String> onSend;
  final bool isSending;
  final String? initialText;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final _controller = TextEditingController(text: widget.initialText);
  late bool _hasText = (widget.initialText ?? '').trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty || widget.isSending) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.graphic_eq_rounded, color: AppColors.secondaryGlow),
              onPressed: () => context.go('/voice'),
              tooltip: 'Voice mode',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.isSending,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask JARVIS anything…',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GlowButton(
              onPressed: (_hasText && !widget.isSending) ? _submit : null,
              padding: const EdgeInsets.all(10),
              child: Icon(widget.isSending ? Icons.hourglass_bottom_rounded : Icons.arrow_upward_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
