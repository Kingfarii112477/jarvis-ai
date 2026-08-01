import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Ambient background: the flat obsidian base plus two slow-drifting glow
/// blobs (cyan + violet) that give every screen depth without costing more
/// than a couple of gradient fills per frame.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, this.animate = true});

  final bool animate;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: widget.animate
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(painter: _GlowFieldPainter(_controller.value)),
              )
            : CustomPaint(painter: _GlowFieldPainter(0)),
      ),
    );
  }
}

class _GlowFieldPainter extends CustomPainter {
  _GlowFieldPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final blobA = Offset(
      size.width * (0.2 + 0.1 * math.sin(t * 2 * math.pi)),
      size.height * (0.18 + 0.06 * math.cos(t * 2 * math.pi)),
    );
    final blobB = Offset(
      size.width * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 1.2)),
      size.height * (0.75 + 0.05 * math.sin(t * 2 * math.pi + 1.2)),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.primaryGlow.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(Rect.fromCircle(center: blobA, radius: size.width * 0.55)),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.secondaryGlow.withValues(alpha: 0.09), Colors.transparent],
        ).createShader(Rect.fromCircle(center: blobB, radius: size.width * 0.6)),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowFieldPainter oldDelegate) => oldDelegate.t != t;
}
