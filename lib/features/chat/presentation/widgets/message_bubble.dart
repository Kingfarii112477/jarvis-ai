import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/chat_message.dart';
import 'code_block_builder.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onRegenerate});

  final ChatMessage message;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser && message.toolUsed != null) ...[
                _ToolBadge(label: message.toolUsed!),
                const SizedBox(width: 8),
              ],
              if (message.isVoice)
                const Icon(Icons.graphic_eq_rounded, size: 13, color: AppColors.textTertiary),
            ],
          ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
              child: GlassCard(
                strong: isUser,
                glowColor: isUser ? null : AppColors.primaryGlow,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
                ),
                child: isUser
                    ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))
                    : MarkdownBody(
                        data: message.text,
                        selectable: true,
                        builders: {'code': CodeBlockBuilder()},
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                          code: TextStyle(
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            color: AppColors.primaryGlow,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: const Border(left: BorderSide(color: AppColors.primaryGlow, width: 3)),
                            color: Colors.white.withValues(alpha: 0.02),
                          ),
                          tableBorder: TableBorder.all(color: AppColors.glassBorder),
                          h1: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          listBullet: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ),
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(icon: Icons.copy_rounded, onTap: () => _copy(context)),
                  _ActionIcon(icon: Icons.share_outlined, onTap: () => Share.share(message.text)),
                  if (onRegenerate != null)
                    _ActionIcon(icon: Icons.refresh_rounded, onTap: onRegenerate!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}

class _ToolBadge extends StatelessWidget {
  const _ToolBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 15, color: AppColors.textTertiary),
      onPressed: onTap,
      splashRadius: 16,
      visualDensity: VisualDensity.compact,
    );
  }
}
