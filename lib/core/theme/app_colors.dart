import 'package:flutter/material.dart';

abstract final class AppPrimaryPalette {
  static const List<Color> colors = <Color>[
    Color(0xFF2196F3),
    Color(0xFF03A9F4),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
  ];
}

/// Semantic color tokens that adapt to the active [Brightness].
///
/// Widgets must never hardcode palette values. Read the active tokens through
/// [AppColorsContext.colors] so every screen follows the selected theme:
///
/// ```dart
/// color: context.colors.textHigh,
/// ```
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceElevated,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.playerGradientTop,
    required this.playerGradientMiddle,
    required this.textHigh,
    required this.textMedium,
    required this.textLow,
    required this.danger,
    required this.success,
    required this.artworkPlaceholder,
    required this.snackBarBackground,
    required this.snackBarContent,
    required this.scrim,
    required this.onScrim,
    required this.onScrimMuted,
    required this.scrimTrack,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceElevated;
  final Color outline;

  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color playerGradientTop;
  final Color playerGradientMiddle;

  final Color textHigh;
  final Color textMedium;
  final Color textLow;

  final Color danger;
  final Color success;

  final Color artworkPlaceholder;

  final Color snackBarBackground;
  final Color snackBarContent;

  /// Always-dark overlay scrim (e.g. mini player over artwork) and the text /
  /// track colors that sit on top of it. Independent of the active theme.
  final Color scrim;
  final Color onScrim;
  final Color onScrimMuted;
  final Color scrimTrack;

  /// Neutral dark scrim for full-screen overlays and route barriers, where no
  /// [BuildContext] is available to read the active theme.
  static const Color scrimOverlay = Color(0x8A000000);

  static const AppColorTokens dark = AppColorTokens(
    background: Color(0xFF080808),
    surface: Color(0xFF121212),
    surfaceHigh: Color(0xFF202020),
    surfaceElevated: Color(0xFF2A2A2A),
    outline: Color(0xFF343434),
    primary: Color(0xFF2196F3),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF90CAF9),
    playerGradientTop: Color(0xFF123A63),
    playerGradientMiddle: Color(0xFF0B2138),
    textHigh: Color(0xFFF5F5F5),
    textMedium: Color(0xFFB3B3B3),
    textLow: Color(0xFF858585),
    danger: Color(0xFFFF5470),
    success: Color(0xFF3DD68C),
    artworkPlaceholder: Color(0xFF2A2A2A),
    snackBarBackground: Color(0xFF2A2A2A),
    snackBarContent: Color(0xFFF5F5F5),
    scrim: scrimOverlay,
    onScrim: Color(0xFFFFFFFF),
    onScrimMuted: Color(0xB3FFFFFF),
    scrimTrack: Color(0x3DFFFFFF),
  );

  static const AppColorTokens light = AppColorTokens(
    background: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECEEF1),
    surfaceElevated: Color(0xFFFFFFFF),
    outline: Color(0xFFD4D9DF),
    primary: Color(0xFF1976D2),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF1565C0),
    playerGradientTop: Color(0xFFD6E6F7),
    playerGradientMiddle: Color(0xFFEDF4FB),
    textHigh: Color(0xFF14181C),
    textMedium: Color(0xFF545B63),
    textLow: Color(0xFF858C93),
    danger: Color(0xFFD32F4A),
    success: Color(0xFF1E9E5A),
    artworkPlaceholder: Color(0xFFECEEF1),
    snackBarBackground: Color(0xFF2B3038),
    snackBarContent: Color(0xFFF5F5F5),
    scrim: scrimOverlay,
    onScrim: Color(0xFFFFFFFF),
    onScrimMuted: Color(0xB3FFFFFF),
    scrimTrack: Color(0x3DFFFFFF),
  );

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceElevated,
    Color? outline,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? playerGradientTop,
    Color? playerGradientMiddle,
    Color? textHigh,
    Color? textMedium,
    Color? textLow,
    Color? danger,
    Color? success,
    Color? artworkPlaceholder,
    Color? snackBarBackground,
    Color? snackBarContent,
    Color? scrim,
    Color? onScrim,
    Color? onScrimMuted,
    Color? scrimTrack,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      outline: outline ?? this.outline,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      playerGradientTop: playerGradientTop ?? this.playerGradientTop,
      playerGradientMiddle: playerGradientMiddle ?? this.playerGradientMiddle,
      textHigh: textHigh ?? this.textHigh,
      textMedium: textMedium ?? this.textMedium,
      textLow: textLow ?? this.textLow,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      artworkPlaceholder: artworkPlaceholder ?? this.artworkPlaceholder,
      snackBarBackground: snackBarBackground ?? this.snackBarBackground,
      snackBarContent: snackBarContent ?? this.snackBarContent,
      scrim: scrim ?? this.scrim,
      onScrim: onScrim ?? this.onScrim,
      onScrimMuted: onScrimMuted ?? this.onScrimMuted,
      scrimTrack: scrimTrack ?? this.scrimTrack,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      playerGradientTop: Color.lerp(
        playerGradientTop,
        other.playerGradientTop,
        t,
      )!,
      playerGradientMiddle: Color.lerp(
        playerGradientMiddle,
        other.playerGradientMiddle,
        t,
      )!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textMedium: Color.lerp(textMedium, other.textMedium, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      artworkPlaceholder: Color.lerp(
        artworkPlaceholder,
        other.artworkPlaceholder,
        t,
      )!,
      snackBarBackground: Color.lerp(
        snackBarBackground,
        other.snackBarBackground,
        t,
      )!,
      snackBarContent: Color.lerp(snackBarContent, other.snackBarContent, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      onScrim: Color.lerp(onScrim, other.onScrim, t)!,
      onScrimMuted: Color.lerp(onScrimMuted, other.onScrimMuted, t)!,
      scrimTrack: Color.lerp(scrimTrack, other.scrimTrack, t)!,
    );
  }
}

/// Reads the active [AppColorTokens] from the current [ThemeData].
extension AppColorsContext on BuildContext {
  AppColorTokens get colors =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.dark;
}
