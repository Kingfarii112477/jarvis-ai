import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// The base "floating glass" surface used everywhere in the app.
///
/// By default this renders a tinted, bordered container with a soft shadow
/// — no [BackdropFilter]. A prior investigation in this codebase found that
/// `BackdropFilter` blur reliably corrupts the framebuffer (washes the
/// whole screen gray) on a number of Android GPU/driver combinations, so
/// heavy blur is opt-in via [GlassCard.blurred] and should only be used on
/// isolated, non-scrolling surfaces (see Settings → Animations →
/// "Experimental heavy blur").
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glowColor,
    this.strong = false,
  }) : _blurSigma = 0;

  const GlassCard.blurred({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glowColor,
    this.strong = false,
    double sigma = 18,
  }) : _blurSigma = sigma;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final bool strong;
  final double _blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    final decoration = BoxDecoration(
      color: strong ? AppColors.glassFillStrong : AppColors.glassFill,
      borderRadius: radius,
      border: Border.all(color: AppColors.glassBorder),
      boxShadow: glowColor == null
          ? const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 12))]
          : [
              BoxShadow(color: glowColor!.withValues(alpha: 0.22), blurRadius: 36, spreadRadius: -4),
              const BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 12)),
            ],
    );

    Widget content = Container(padding: padding, decoration: decoration, child: child);

    if (_blurSigma > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: content,
        ),
      );
    }

    return content;
  }
}
