import 'package:flutter/material.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(AppColorTokens.dark, Brightness.dark);

  static ThemeData light() => _build(AppColorTokens.light, Brightness.light);

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.accent,
      error: tokens.danger,
      surface: tokens.surface,
    ).copyWith(
      surfaceContainerHighest: tokens.surfaceHigh,
      onSurface: tokens.textHigh,
      onSurfaceVariant: tokens.textMedium,
      outline: tokens.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textHigh,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: tokens.textHigh,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tokens.textHigh,
        unselectedLabelColor: tokens.textHigh.withValues(alpha: 0.3),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: tokens.primary,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        splashFactory: NoSplash.splashFactory,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.snackBarBackground,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: tokens.snackBarContent,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: tokens.textHigh,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14.5,
          height: 1.6,
          color: tokens.textMedium,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
        ),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: tokens.primary,
        thumbColor: tokens.primary,
        inactiveTrackColor: tokens.outline,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surfaceHigh,
        hintStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: tokens.textLow,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: tokens.primary, width: 1.4),
        ),
        contentPadding: AppSpacing.hMdVSm,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textMedium,
        titleTextStyle: AppTypography.songTitle.copyWith(
          color: tokens.textHigh,
        ),
        subtitleTextStyle: AppTypography.songSubtitle.copyWith(
          color: tokens.textMedium,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
      ),
    );
  }
}
