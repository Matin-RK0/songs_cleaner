import 'package:flutter/material.dart';

/// Semantic foreground/background pairs retain contrast in both theme modes.
abstract final class AppAvatarPalette {
  static const variants = 6;

  static ({Color background, Color foreground}) colors(
    ColorScheme colors,
    int index,
  ) => switch (index % variants) {
    0 => (
      background: colors.primaryContainer,
      foreground: colors.onPrimaryContainer,
    ),
    1 => (
      background: colors.secondaryContainer,
      foreground: colors.onSecondaryContainer,
    ),
    2 => (
      background: colors.tertiaryContainer,
      foreground: colors.onTertiaryContainer,
    ),
    3 => (background: colors.primary, foreground: colors.onPrimary),
    4 => (background: colors.secondary, foreground: colors.onSecondary),
    _ => (background: colors.tertiary, foreground: colors.onTertiary),
  };
}
