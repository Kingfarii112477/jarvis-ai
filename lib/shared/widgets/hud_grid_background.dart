import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Faint animated grid + radial vignette used as the base layer behind
/// the HUD. Static geometry, cheap to paint, no per-frame rebuild needed.
class HudGridBackground extends StatelessWidget {
  const HudGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HudGridPainter(),
        ),
      ),
    );
  }
}

class _HudGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Radial vignette glow from the center
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.hudLine.withOpacity(0.05),
          AppColors.background.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.4),
          radius: size.width,
        ),
      );
    canvas.drawRect(Offset.zero & size, vignette);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.hudGrid
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudGridPainter oldDelegate) => false;
}
