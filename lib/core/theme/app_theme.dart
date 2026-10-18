import 'package:flutter/material.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark({Color? primary}) =>
      _build(_withPrimary(AppColorTokens.dark, primary), Brightness.dark);

  static ThemeData light({Color? primary}) =>
      _build(_withPrimary(AppColorTokens.light, primary), Brightness.light);

  static AppColorTokens _withPrimary(AppColorTokens tokens, Color? primary) {
    if (primary == null) return tokens;
    final onPrimary = primary.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return tokens.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      accent: primary,
    );
  }

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
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
        titleTextStyle: AppTypography.appBarTitle.copyWith(
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
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabelUnselected,
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
      cardTheme: CardThemeData(
        color: tokens.surfaceHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          elevation: 0,
          padding: AppSpacing.hMdVSm,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.outline),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceHigh,
        selectedColor: tokens.primary.withValues(alpha: 0.16),
        side: BorderSide(color: tokens.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
        labelStyle: AppTypography.caption.copyWith(color: tokens.textHigh),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        elevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: AppTypography.sheetTitle.copyWith(
          color: tokens.textHigh,
        ),
        contentTextStyle: AppTypography.dialogBody.copyWith(
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
        minVerticalPadding: AppSpacing.xs,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.outline.withValues(alpha: 0.65),
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.primary,
        selectionColor: tokens.primary.withValues(alpha: 0.24),
        selectionHandleColor: tokens.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.primary),
    );
  }
}
