import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

enum OrbState { idle, listening, processing, speaking }

/// The central "holographic core" — a radar-style HUD reticle standing in
/// for the assistant's presence. Concentric rings, tick marks, a rotating
/// segmented ring and a plasma center replace the old soft glowing orb,
/// while keeping the same public API (OrbState, size) so nothing else in
/// the app needs to change.
class AnimatedOrb extends StatefulWidget {
  final OrbState state;
  final double size;

  const AnimatedOrb({
    super.key,
    required this.state,
    this.size = 200,
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  late final AnimationController _rotationControllerReverse;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _rotationControllerReverse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _rotationControllerReverse.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _rotationControllerReverse,
        _waveController,
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: HolographicCorePainter(
            state: widget.state,
            pulse: _pulseController.value,
            rotation: _rotationController.value,
            rotationReverse: _rotationControllerReverse.value,
            wave: _waveController.value,
          ),
        );
      },
    );
  }
}

class HolographicCorePainter extends CustomPainter {
  final OrbState state;
  final double pulse;
  final double rotation;
  final double rotationReverse;
  final double wave;

  HolographicCorePainter({
    required this.state,
    required this.pulse,
    required this.rotation,
    required this.rotationReverse,
    required this.wave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.32;

    _drawAmbientGlow(canvas, center, baseRadius);
    _drawTickRing(canvas, center, baseRadius * 1.55);
    _drawSegmentedRing(canvas, center, baseRadius * 1.3);
    _drawCrosshair(canvas, center, baseRadius * 1.55);

    if (state == OrbState.listening) {
      _drawPingRings(canvas, center, baseRadius);
    } else if (state == OrbState.processing) {
      _drawScanSweep(canvas, center, baseRadius * 1.3);
    } else if (state == OrbState.speaking) {
      _drawVoiceBars(canvas, center, baseRadius);
    }

    _drawCore(canvas, center, baseRadius);
  }

  Color get _accent {
    switch (state) {
      case OrbState.listening:
        return AppColors.hudLine;
      case OrbState.processing:
        return AppColors.primary;
      case OrbState.speaking:
        return AppColors.secondary;
      case OrbState.idle:
        return AppColors.hudLine;
    }
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, double baseRadius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _accent.withOpacity(0.22 * (0.8 + pulse * 0.2)),
          _accent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 2.2));
    canvas.drawCircle(center, baseRadius * 2.2, glowPaint);
  }

  /// A radar-style ring of short tick marks, like a targeting reticle
  /// etched around the core. Every 4th tick is longer, and slowly rotates.
  void _drawTickRing(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = AppColors.hudLine.withOpacity(0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const tickCount = 48;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationReverse * 2 * math.pi * 0.15);
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * math.pi;
      final isLong = i % 4 == 0;
      final inner = radius - (isLong ? 10 : 5);
      final outer = radius;
      final p1 = Offset(math.cos(angle) * inner, math.sin(angle) * inner);
      final p2 = Offset(math.cos(angle) * outer, math.sin(angle) * outer);
      canvas.drawLine(
        p1,
        p2,
        tickPaint..color = AppColors.hudLine.withOpacity(isLong ? 0.6 : 0.28),
      );
    }
    canvas.restore();
  }

  /// A ring broken into arced segments that rotates opposite the ticks —
  /// number of lit segments reacts to state.
  void _drawSegmentedRing(Canvas canvas, Offset center, double radius) {
    const segments = 10;
    const gap = math.pi / 90; // small gap between segments
    final sweep = (2 * math.pi / segments) - gap;

    final lit = switch (state) {
      OrbState.idle => 3,
      OrbState.listening => 5,
      OrbState.processing => segments,
      OrbState.speaking => 7,
    };

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < segments; i++) {
      final start = i * (sweep + gap);
      final isLit = i < lit;
      final paint = Paint()
        ..color = _accent.withOpacity(isLit ? 0.85 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
    canvas.restore();
  }

  /// Faint crosshair lines, echoing the HudFrame corner-bracket language
  /// used elsewhere in the app.
  void _drawCrosshair(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = AppColors.hudLine.withOpacity(0.18)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - radius * 1.15, center.dy),
      Offset(center.dx - radius * 0.75, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.75, center.dy),
      Offset(center.dx + radius * 1.15, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 1.15),
      Offset(center.dx, center.dy - radius * 0.75),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 0.75),
      Offset(center.dx, center.dy + radius * 1.15),
      linePaint,
    );
  }

  void _drawPingRings(Canvas canvas, Offset center, double baseRadius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (int i = 0; i < 2; i++) {
      final t = (wave + i / 2) % 1.0;
      final radius = baseRadius * (1.05 + t * 0.7);
      canvas.drawCircle(
        center,
        radius,
        ringPaint..color = AppColors.hudLine.withOpacity(0.5 * (1.0 - t)),
      );
    }
  }

  void _drawScanSweep(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary.withOpacity(0.5),
        ],
        transform: GradientRotation(rotation * 2 * math.pi),
      ).createShader(rect);
    canvas.drawArc(rect, 0, 2 * math.pi, true, sweepPaint);
  }

  void _drawVoiceBars(Canvas canvas, Offset center, double baseRadius) {
    const barCount = 24;
    final barPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi;
      final n = math.sin((wave * 2 * math.pi) + i * 1.3).abs();
      final len = baseRadius * (0.12 + n * 0.22);
      final innerR = baseRadius * 0.95;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * innerR;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (innerR + len);
      canvas.drawLine(p1, p2, barPaint..color = AppColors.secondary.withOpacity(0.35 + n * 0.5));
    }
  }

  void _drawCore(Canvas canvas, Offset center, double baseRadius) {
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          _accent.withOpacity(0.85),
          AppColors.background,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawCircle(center, baseRadius * (0.62 + pulse * 0.05), orbPaint);

    final edgePaint = Paint()
      ..color = _accent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, baseRadius * (0.62 + pulse * 0.05), edgePaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      center.translate(-baseRadius * 0.15, -baseRadius * 0.15),
      baseRadius * 0.18,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HolographicCorePainter oldDelegate) => true;
}
