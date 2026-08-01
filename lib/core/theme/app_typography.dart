import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// The spec calls for SF Pro Display / Satoshi — both are proprietary and
/// can't be redistributed. Inter is the closest open, production-safe
/// match (same geometric-grotesk family the SF Pro-inspired premium apps
/// use) and ships through `google_fonts`, so we standardize on it here
/// instead of silently degrading to the platform default.
class AppTypography {
  const AppTypography._();

  static TextTheme get textTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textPrimary),
          bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
          bodySmall: base.bodySmall?.copyWith(color: AppColors.textTertiary),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          labelSmall: base.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        )
        .apply(fontFamily: GoogleFonts.inter().fontFamily);
  }

  static TextStyle get monoLabel => GoogleFonts.jetBrainsMono(
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 1.2,
      );
}
