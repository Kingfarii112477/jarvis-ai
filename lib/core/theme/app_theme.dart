import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark({Color accent = AppColors.primaryGlow}) {
    final colorScheme = ColorScheme.dark(
      primary: accent,
      secondary: AppColors.secondaryGlow,
      tertiary: AppColors.accent,
      surface: AppColors.card,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSurface: AppColors.textPrimary,
      outline: AppColors.glassBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : AppColors.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.35)
              : AppColors.glassFillStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: AppColors.glassBorderStrong,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassFill,
        side: const BorderSide(color: AppColors.glassBorder),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Color(0x2200E5FF),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Accent options exposed in Settings — each remaps the primary glow color
/// used across the orb, buttons and highlights app-wide.
enum AppAccent { cyan, violet, magenta, mint }

extension AppAccentColor on AppAccent {
  Color get color {
    switch (this) {
      case AppAccent.cyan:
        return AppColors.primaryGlow;
      case AppAccent.violet:
        return AppColors.secondaryGlow;
      case AppAccent.magenta:
        return AppColors.accent;
      case AppAccent.mint:
        return AppColors.success;
    }
  }

  String get label {
    switch (this) {
      case AppAccent.cyan:
        return 'Cyan';
      case AppAccent.violet:
        return 'Violet';
      case AppAccent.magenta:
        return 'Magenta';
      case AppAccent.mint:
        return 'Mint';
    }
  }
}
