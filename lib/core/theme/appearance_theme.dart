import 'package:material_ui/material_ui.dart';

import '../settings/appearance_preferences.dart';
import 'app_colors.dart';

abstract final class AppearanceTheme {
  static Color photoTint(Brightness brightness) =>
      brightness == Brightness.dark ? Colors.black : Colors.white;

  static AppColorTokens systemTokens(
    AppColorTokens defaults,
    ColorScheme scheme,
  ) => defaults.copyWith(
    background: scheme.surface,
    surface: scheme.surfaceContainerLow,
    surfaceHigh: scheme.surfaceContainerHigh,
    surfaceElevated: scheme.surfaceContainerHighest,
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    accent: scheme.secondary,
    outline: scheme.outlineVariant,
    textHigh: scheme.onSurface,
    textMedium: scheme.onSurfaceVariant,
    textLow: scheme.onSurfaceVariant,
    danger: scheme.error,
    playerGradientTop: scheme.primaryContainer,
    playerGradientMiddle: scheme.surfaceContainer,
    artworkPlaceholder: scheme.surfaceContainerHighest,
    snackBarBackground: scheme.inverseSurface,
    snackBarContent: scheme.onInverseSurface,
  );

  static AppColorTokens customTokens(
    AppColorTokens tokens,
    AppearancePreferences appearance,
    Brightness brightness,
  ) {
    final solid = appearance.backgroundColor;
    final foreground = appearance.foregroundColor;
    final photo = appearance.backgroundKind == AppBackgroundKind.photo;
    if (solid == null && foreground == null && !photo) return tokens;

    final background = solid == null ? tokens.background : Color(solid);
    final canvas = photo
        ? Color.alphaBlend(
            photoTint(brightness).withValues(alpha: appearance.photoDimming),
            brightness == Brightness.dark ? Colors.white : Colors.black,
          )
        : background;
    final chosen = foreground == null ? tokens.textHigh : Color(foreground);
    final textEndpoint = preferredForeground(canvas);
    final surfaceTint = textEndpoint == Colors.white
        ? Colors.black
        : Colors.white;
    // Let an extreme custom background flip its text polarity without changing
    // the rest of the appearance mode (e.g. a white canvas in the dark theme).
    final surfaces = solid == null
        ? tokens
        : tokens.copyWith(
            surface: Color.lerp(background, surfaceTint, 0.04),
            surfaceHigh: Color.lerp(background, surfaceTint, 0.08),
            surfaceElevated: Color.lerp(background, surfaceTint, 0.12),
            artworkPlaceholder: Color.lerp(background, surfaceTint, 0.12),
          );
    final canvasAndPanels = [
      canvas,
      background,
      surfaces.surface,
      surfaces.surfaceHigh,
      surfaces.surfaceElevated,
    ];
    final reference = canvasAndPanels.reduce(
      (a, b) =>
          _contrast(a, textEndpoint) <= _contrast(b, textEndpoint) ? a : b,
    );
    final high = readable(chosen, reference, endpoint: textEndpoint);
    final medium = readable(
      Color.lerp(high, reference, 0.25)!,
      reference,
      endpoint: textEndpoint,
    );
    final primary = readable(tokens.primary, reference, endpoint: textEndpoint);
    final onArtwork = foreground == null
        ? null
        : readable(
            chosen,
            Color.alphaBlend(tokens.scrim, Colors.white),
            endpoint: Colors.white,
          );
    return surfaces.copyWith(
      background: background,
      textHigh: high,
      textMedium: medium,
      textLow: medium,
      primary: primary,
      onPrimary: primary == tokens.primary
          ? tokens.onPrimary
          : preferredForeground(primary),
      outline: solid == null
          ? tokens.outline
          : Color.lerp(background, high, 0.25),
      onScrim: onArtwork,
      onScrimMuted: onArtwork,
      snackBarContent: foreground == null
          ? null
          : readable(chosen, tokens.snackBarBackground),
    );
  }

  static Color preferredForeground(Color background) =>
      _contrast(Colors.black, background) >= _contrast(Colors.white, background)
      ? Colors.black
      : Colors.white;

  static Color readable(Color color, Color background, {Color? endpoint}) {
    const minimumContrast = 4.5;
    final target = endpoint ?? preferredForeground(background);
    final luminance = background.computeLuminance();
    final correctPolarity =
        (color.computeLuminance() > luminance) == (target == Colors.white);
    if ((endpoint == null || correctPolarity) &&
        _contrast(color, background) >= minimumContrast) {
      return color;
    }
    var low = 0.0;
    var high = 1.0;
    for (var step = 0; step < 12; step++) {
      final t = (low + high) / 2;
      final candidate = Color.lerp(color, target, t)!;
      if ((candidate.computeLuminance() > luminance) ==
              (target == Colors.white) &&
          _contrast(candidate, background) >= minimumContrast) {
        high = t;
      } else {
        low = t;
      }
    }
    return Color.lerp(color, target, high)!;
  }

  static double _contrast(Color a, Color b) {
    final x = a.computeLuminance() + 0.05;
    final y = b.computeLuminance() + 0.05;
    return x >= y ? x / y : y / x;
  }
}
