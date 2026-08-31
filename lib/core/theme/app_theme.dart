import 'package:flutter/material.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.surface,
    ).copyWith(surfaceContainerHighest: AppColors.surfaceHigh);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textHigh,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textHigh,
        unselectedLabelColor: AppColors.textHigh.withValues(alpha: 0.3),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: AppColors.primary,
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
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textHigh,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textHigh,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14.5,
          height: 1.6,
          color: AppColors.textMedium,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
        ),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        inactiveTrackColor: AppColors.outline,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        hintStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textLow,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: AppSpacing.hMdVSm,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMedium,
        titleTextStyle: AppTypography.songTitle,
        subtitleTextStyle: AppTypography.songSubtitle,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
