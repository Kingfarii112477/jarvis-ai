import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'orb_painter.dart';

/// The soul of the app. A procedurally-animated core rendered every frame
/// with [CustomPainter] (gradients, radial glows and a live particle
/// field) rather than a static Lottie loop, so it genuinely reacts to
/// [mood] and, when supplied, a real microphone [amplitude] instead of
/// faking motion.
class JarvisOrb extends StatefulWidget {
  const JarvisOrb({
    super.key,
    required this.mood,
    this.size = 220,
    this.amplitude,
    this.onTap,
    this.accent,
  });

  final AssistantMood mood;
  final double size;

  /// 0..1 real audio amplitude (mic input while listening, playback level
  /// while speaking). When null the orb still animates, just without
  /// audio-reactive modulation.
  final double? amplitude;

  final VoidCallback? onTap;
  final Color? accent;

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final AnimationController _rotate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final AnimationController _rotateReverse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  late final _ParticleField _particles = _ParticleField(count: 28);
  late final AnimationController _particleTicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 16),
  )..addListener(() => _particles.step())
    ..repeat();

  @override
  void dispose() {
    _breath.dispose();
    _rotate.dispose();
    _rotateReverse.dispose();
    _wave.dispose();
    _particleTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? widget.mood.color;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _rotate, _rotateReverse, _wave, _particleTicker]),
          builder: (context, _) {
            return CustomPaint(
              size: Size.square(widget.size),
              painter: OrbPainter(
                mood: widget.mood,
                accent: accent,
                breath: _breath.value,
                rotation: _rotate.value,
                rotationReverse: _rotateReverse.value,
                wave: _wave.value,
                amplitude: widget.amplitude,
                particles: _particles.snapshot,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A tiny self-contained particle simulation: particles drift on a slow
/// orbit and pulse their radius, giving [OrbPainter] a live field to
/// render instead of a static ring of dots.
class _ParticleField {
  _ParticleField({required this.count}) {
    _particles = List.generate(count, (i) => _SimParticle.random(i));
  }

  final int count;
  late List<_SimParticle> _particles;

  List<OrbParticle> get snapshot => [
        for (final p in _particles)
          OrbParticle(
            angle: p.angle,
            radiusFraction: p.baseRadiusFraction * (0.85 + 0.15 * (p.radiusPhase * 2 - 1).abs()),
            size: p.size,
          ),
      ];

  void step() {
    for (final p in _particles) {
      p.angle += p.speed;
      p.radiusPhase += 0.004 * p.driftDirection;
      if (p.radiusPhase > 1 || p.radiusPhase < 0) p.driftDirection *= -1;
    }
  }
}

class _SimParticle {
  _SimParticle({
    required this.angle,
    required this.speed,
    required this.baseRadiusFraction,
    required this.radiusPhase,
    required this.driftDirection,
    required this.size,
  });

  factory _SimParticle.random(int seed) {
    final rnd = (seed * 9973) % 1000 / 1000;
    final rnd2 = (seed * 4111) % 1000 / 1000;
    return _SimParticle(
      angle: rnd * 6.28318,
      speed: 0.002 + rnd2 * 0.004,
      baseRadiusFraction: 0.55 + rnd * 0.4,
      radiusPhase: rnd2,
      driftDirection: seed.isEven ? 1 : -1,
      size: 1.0 + rnd2 * 1.6,
    );
  }

  double angle;
  double speed;
  double baseRadiusFraction;
  double radiusPhase;
  int driftDirection;
  double size;
}
