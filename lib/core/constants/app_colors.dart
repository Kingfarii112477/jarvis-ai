import 'package:flutter/material.dart';

/// The JARVIS "Dark Obsidian" palette. Every screen in the app pulls its
/// colors from here — nothing is hardcoded inline so the whole theme can be
/// re-tuned from one place.
class AppColors {
  const AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF05070B);
  static const Color card = Color(0xFF0D1118);
  static const Color cardElevated = Color(0xFF121722);

  // Glass
  static const Color glassFill = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color glassFillStrong = Color(0x14FFFFFF); // ~0.08
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassBorderStrong = Color(0x26FFFFFF);

  // Glow / brand
  static const Color primaryGlow = Color(0xFF00E5FF);
  static const Color secondaryGlow = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF9D4EDD);

  // Semantic
  static const Color success = Color(0xFF00FFB2);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF4D6D);

  // Text
  static const Color textPrimary = Color(0xFFF4F6FA);
  static const Color textSecondary = Color(0xFFA6ADBB);
  static const Color textTertiary = Color(0xFF6B7280);

  /// Signature multi-hue glow gradient used across hero surfaces, orb
  /// halos and the primary CTA.
  static const List<Color> auroraGradient = [
    primaryGlow,
    secondaryGlow,
    accent,
  ];

  static RadialGradient glowRadial(Color color, {double opacity = 0.35}) {
    return RadialGradient(
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ],
    );
  }
}

/// Maps each orb / assistant lifecycle state to a color so painters, chips
/// and status text all agree on what "listening" looks like.
enum AssistantMood { idle, listening, processing, speaking, offline, error, success }

extension AssistantMoodColor on AssistantMood {
  Color get color {
    switch (this) {
      case AssistantMood.idle:
        return AppColors.primaryGlow;
      case AssistantMood.listening:
        return AppColors.secondaryGlow;
      case AssistantMood.processing:
        return AppColors.accent;
      case AssistantMood.speaking:
        return AppColors.primaryGlow;
      case AssistantMood.offline:
        return AppColors.textTertiary;
      case AssistantMood.error:
        return AppColors.error;
      case AssistantMood.success:
        return AppColors.success;
    }
  }

  String get label {
    switch (this) {
      case AssistantMood.idle:
        return 'IDLE';
      case AssistantMood.listening:
        return 'LISTENING';
      case AssistantMood.processing:
        return 'PROCESSING';
      case AssistantMood.speaking:
        return 'SPEAKING';
      case AssistantMood.offline:
        return 'OFFLINE';
      case AssistantMood.error:
        return 'ERROR';
      case AssistantMood.success:
        return 'READY';
    }
  }
}
