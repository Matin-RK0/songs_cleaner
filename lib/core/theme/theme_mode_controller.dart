import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';

/// Selected app theme. Defaults to dark so the app keeps its original look
/// until the user picks another mode in Settings.
final appThemeModeProvider =
    NotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

class AppThemeModeController extends Notifier<ThemeMode> {
  static const ThemeMode _fallback = ThemeMode.dark;

  @override
  ThemeMode build() {
    final stored = ref
        .watch(appSettingsRepositoryProvider)
        .loadThemeMode(_fallback.name);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => _fallback,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(appSettingsRepositoryProvider).saveThemeMode(mode.name);
  }
}
