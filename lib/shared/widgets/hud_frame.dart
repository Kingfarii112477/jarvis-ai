import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Draws targeting-style corner brackets around whatever it wraps,
/// like a HUD viewport frame.
class HudFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const HudFrame({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: margin,
              child: CustomPaint(
                painter: _CornerBracketPainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hudLine.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const len = 22.0;

    void bracket(Offset corner, Offset horiz, Offset vert) {
      canvas.drawLine(corner, horiz, paint);
      canvas.drawLine(corner, vert, paint);
    }

    // Top-left
    bracket(
      const Offset(0, 0),
      const Offset(len, 0),
      const Offset(0, len),
    );
    // Top-right
    bracket(
      Offset(size.width, 0),
      Offset(size.width - len, 0),
      Offset(size.width, len),
    );
    // Bottom-left
    bracket(
      Offset(0, size.height),
      Offset(len, size.height),
      Offset(0, size.height - len),
    );
    // Bottom-right
    bracket(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      Offset(size.width, size.height - len),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) => false;
}
