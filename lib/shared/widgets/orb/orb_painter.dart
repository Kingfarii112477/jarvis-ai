import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Immutable snapshot of a single ambient particle, computed by
/// `_ParticleField` in [JarvisOrb] and handed to the painter each frame.
class OrbParticle {
  const OrbParticle({required this.angle, required this.radiusFraction, required this.size});
  final double angle;
  final double radiusFraction;
  final double size;
}

/// Paints the JARVIS core. Every visual is procedural — computed per frame
/// from the animation values passed in — rather than a pre-baked asset, so
/// mood changes are instant and audio [amplitude] genuinely deforms the
/// waveform ring rather than looping a canned animation.
class OrbPainter extends CustomPainter {
  OrbPainter({
    required this.mood,
    required this.accent,
    required this.breath,
    required this.rotation,
    required this.rotationReverse,
    required this.wave,
    required this.particles,
    this.amplitude,
  });

  final AssistantMood mood;
  final Color accent;
  final double breath; // 0..1 breathing cycle
  final double rotation; // 0..1 loop
  final double rotationReverse; // 0..1 loop
  final double wave; // 0..1 loop, drives waveform/ripple timing
  final double? amplitude; // 0..1 real audio level, optional
  final List<OrbParticle> particles;

  double get _level => amplitude ?? (0.35 + 0.25 * math.sin(wave * 2 * math.pi));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.30;

    _paintAmbientGlow(canvas, center, baseRadius);
    _paintOrbitRing(canvas, center, baseRadius);
    _paintParticles(canvas, center, baseRadius);

    switch (mood) {
      case AssistantMood.idle:
        _paintIdleHalo(canvas, center, baseRadius);
      case AssistantMood.listening:
        _paintListeningRings(canvas, center, baseRadius);
        _paintWaveformRing(canvas, center, baseRadius, dense: true);
      case AssistantMood.processing:
        _paintProcessingField(canvas, center, baseRadius);
      case AssistantMood.speaking:
        _paintWaveformRing(canvas, center, baseRadius, dense: false);
      case AssistantMood.offline:
        break;
      case AssistantMood.error:
        _paintBurst(canvas, center, baseRadius);
      case AssistantMood.success:
        _paintSuccessRipple(canvas, center, baseRadius);
    }

    _paintCore(canvas, center, baseRadius);
  }

  void _paintAmbientGlow(Canvas canvas, Offset center, double r) {
    final desaturated = mood == AssistantMood.offline;
    final glowColor = desaturated ? AppColors.textTertiary : accent;
    final intensity = desaturated ? 0.14 : 0.28 + breath * 0.12;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor.withValues(alpha: intensity), glowColor.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.6));
    canvas.drawCircle(center, r * 2.6, paint);
  }

  void _paintOrbitRing(Canvas canvas, Offset center, double r) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 1.55, ringPaint);

    // A handful of slow orbiting dots along the ring for depth.
    final dotPaint = Paint()..color = accent.withValues(alpha: 0.5);
    for (int i = 0; i < 3; i++) {
      final angle = rotationReverse * 2 * math.pi + (i * 2 * math.pi / 3);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r * 1.55;
      canvas.drawCircle(p, 1.6, dotPaint);
    }
  }

  void _paintParticles(Canvas canvas, Offset center, double r) {
    final attraction = switch (mood) {
      AssistantMood.listening => 0.55,
      AssistantMood.processing => 0.35,
      AssistantMood.error => 1.3,
      _ => 1.0,
    };
    final color = mood == AssistantMood.offline ? AppColors.textTertiary : accent;
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    for (final p in particles) {
      final radius = r * p.radiusFraction * attraction;
      final offset = center + Offset(math.cos(p.angle), math.sin(p.angle)) * radius;
      canvas.drawCircle(offset, p.size, paint);
    }
  }

  void _paintIdleHalo(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, r * (1.08 + breath * 0.04), paint);
  }

  void _paintListeningRings(Canvas canvas, Offset center, double r) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8;
    for (int i = 0; i < 3; i++) {
      final t = (wave + i / 3) % 1.0;
      final radius = r * (1.0 + t * 0.9);
      paint.color = accent.withValues(alpha: (1.0 - t) * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintProcessingField(Canvas canvas, Offset center, double r) {
    const segments = 12;
    const gap = math.pi / 60;
    const sweep = (2 * math.pi / segments) - gap;
    final rect = Rect.fromCircle(center: center, radius: r * 1.35);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);
    for (int i = 0; i < segments; i++) {
      final lit = i.isEven;
      final paint = Paint()
        ..color = accent.withValues(alpha: lit ? 0.8 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, i * (sweep + gap), sweep, false, paint);
    }
    canvas.restore();

    // Counter-rotating inner ring for the "energy field" layering.
    final innerRect = Rect.fromCircle(center: center, radius: r * 1.12);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotationReverse * 2 * math.pi * 1.4);
    canvas.translate(-center.dx, -center.dy);
    final innerPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawArc(innerRect, 0, math.pi * 0.6, false, innerPaint);
    canvas.drawArc(innerRect, math.pi, math.pi * 0.6, false, innerPaint);
    canvas.restore();
  }

  void _paintWaveformRing(Canvas canvas, Offset center, double r, {required bool dense}) {
    final barCount = dense ? 40 : 28;
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi;
      final n = (math.sin((wave * 2 * math.pi) + i * 1.15).abs() * 0.6) + _level * 0.5;
      final len = r * (0.14 + n * 0.34);
      final innerR = r * 0.98;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * innerR;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (innerR + len);
      paint.color = accent.withValues(alpha: 0.35 + n * 0.55);
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _paintBurst(Canvas canvas, Offset center, double r) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4;
    for (int i = 0; i < 2; i++) {
      final t = (wave + i / 2) % 1.0;
      paint.color = AppColors.error.withValues(alpha: (1.0 - t) * 0.7);
      canvas.drawCircle(center, r * (1.0 + t * 1.4), paint);
    }
    final flashPaint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.15 * (1 - wave))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 1.6, flashPaint);
  }

  void _paintSuccessRipple(Canvas canvas, Offset center, double r) {
    final t = wave;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = AppColors.success.withValues(alpha: (1.0 - t) * 0.65);
    canvas.drawCircle(center, r * (1.0 + t * 0.8), paint);
  }

  void _paintCore(Canvas canvas, Offset center, double r) {
    final desaturated = mood == AssistantMood.offline;
    final coreColor = desaturated ? AppColors.textTertiary : accent;
    final coreScale = desaturated ? 0.6 : 0.6 + breath * 0.06 + _level * 0.04;

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.92),
          coreColor.withValues(alpha: 0.9),
          AppColors.background,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * coreScale));
    canvas.drawCircle(center, r * coreScale, corePaint);

    final edgePaint = Paint()
      ..color = coreColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, r * coreScale, edgePaint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      center.translate(-r * 0.16, -r * 0.16),
      r * 0.16,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
