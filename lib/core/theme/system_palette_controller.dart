import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ColorScheme;

typedef SystemPalette = ({ColorScheme light, ColorScheme dark});

final systemPaletteProvider = FutureProvider<SystemPalette?>((ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  const channel = MethodChannel('com.example.songs_cleaner/system_palette');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'paletteChanged') ref.invalidateSelf();
  });
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(() {
    lifecycle.dispose();
    channel.setMethodCallHandler(null);
  });
  try {
    final colors = await channel.invokeMapMethod<String, Object?>('getPalette');
    final light = _decodeScheme(colors?['light'], Brightness.light);
    final dark = _decodeScheme(colors?['dark'], Brightness.dark);
    if (light == null || dark == null) return null;
    return (light: light, dark: dark);
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
});

ColorScheme? _decodeScheme(Object? roles, Brightness brightness) {
  if (roles is! Map) return null;
  Color? role(String name) => switch (roles[name]) {
    final int value => Color(value),
    _ => null,
  };
  final primary = role('primary');
  final onPrimary = role('onPrimary');
  if (primary == null || onPrimary == null) return null;
  return ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: role('primaryContainer'),
    onPrimaryContainer: role('onPrimaryContainer'),
    secondary: role('secondary'),
    onSecondary: role('onSecondary'),
    secondaryContainer: role('secondaryContainer'),
    onSecondaryContainer: role('onSecondaryContainer'),
    tertiary: role('tertiary'),
    onTertiary: role('onTertiary'),
    tertiaryContainer: role('tertiaryContainer'),
    onTertiaryContainer: role('onTertiaryContainer'),
    surface: role('surface'),
    onSurface: role('onSurface'),
    onSurfaceVariant: role('onSurfaceVariant'),
    surfaceContainerLowest: role('surfaceContainerLowest'),
    surfaceContainerLow: role('surfaceContainerLow'),
    surfaceContainer: role('surfaceContainer'),
    surfaceContainerHigh: role('surfaceContainerHigh'),
    surfaceContainerHighest: role('surfaceContainerHighest'),
    surfaceBright: role('surfaceBright'),
    surfaceDim: role('surfaceDim'),
    outline: role('outline'),
    outlineVariant: role('outlineVariant'),
    inverseSurface: role('inverseSurface'),
    onInverseSurface: role('onInverseSurface'),
    inversePrimary: role('inversePrimary'),
    error: role('error'),
    onError: role('onError'),
    errorContainer: role('errorContainer'),
    onErrorContainer: role('onErrorContainer'),
  );
}
