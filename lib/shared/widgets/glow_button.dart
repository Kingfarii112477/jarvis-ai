import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// A magnetic, glowing pill button used for primary CTAs (send, run
/// workflow, save). Scales down and brightens its glow on press for a
/// tactile "premium" micro-interaction.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.primaryGlow,
    this.filled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final bool filled;
  final EdgeInsetsGeometry padding;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.filled
                ? widget.color.withValues(alpha: disabled ? 0.25 : 1)
                : Colors.transparent,
            border: widget.filled ? null : Border.all(color: widget.color.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: disabled || !widget.filled
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: _pressed ? 0.55 : 0.35),
                      blurRadius: _pressed ? 26 : 18,
                      spreadRadius: _pressed ? 1 : 0,
                    ),
                  ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.filled ? Colors.black : widget.color,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: widget.filled ? Colors.black : widget.color),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
