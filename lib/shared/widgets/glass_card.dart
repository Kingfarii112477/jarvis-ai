import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// A translucent "glass" panel. Previously used BackdropFilter for a real
/// frosted-glass blur, but BackdropFilter is known to corrupt the entire
/// framebuffer (washing the whole screen to flat gray) on a number of
/// Android GPU/driver combinations. We now render a plain semi-transparent
/// tinted container instead — visually close enough to read as "glass"
/// without the driver risk.
class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 10.0,
    this.padding,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16.0);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: content,
    );
  }
}
