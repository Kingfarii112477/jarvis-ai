import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// A slow-moving horizontal scanline band plus static fine scanlines,
/// layered above the content to sell the "holographic display" feel.
/// Kept very low-opacity so it never fights with legibility.
class ScanlineOverlay extends StatefulWidget {
  const ScanlineOverlay({super.key});

  @override
  State<ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<ScanlineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ScanlinePainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fine static scanlines across the whole screen — spaced further apart
    // and much lower opacity so they read as a subtle texture, not a wash.
    final finePaint = Paint()
      ..color = Colors.black.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), finePaint);
    }

    // A brighter sweeping band that travels top to bottom and loops.
    final bandY = progress * (size.height + 160) - 80;
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.hudLine.withOpacity(0.0),
          AppColors.hudLine.withOpacity(0.05),
          AppColors.hudLine.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, bandY - 80, size.width, 160));
    canvas.drawRect(Rect.fromLTWH(0, bandY - 80, size.width, 160), bandPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
