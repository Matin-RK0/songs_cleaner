import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';
import 'app_colors.dart';

final appPrimaryColorProvider =
    NotifierProvider<AppPrimaryColorController, Color>(
      AppPrimaryColorController.new,
    );

class AppPrimaryColorController extends Notifier<Color> {
  @override
  Color build() {
    final settings = ref.watch(appSettingsRepositoryProvider);
    final custom = settings.loadPrimaryColorArgb();
    if (custom != null && custom >= 0 && custom <= 0xffffffff) {
      return Color(custom).withAlpha(255);
    }
    return AppPrimaryPalette.colors[_validIndex(
      settings.loadPrimaryColorIndex(0),
    )];
  }

  Future<void> setColor(Color color) async {
    final opaque = color.withAlpha(255);
    if (state != opaque) {
      await ref
          .read(appSettingsRepositoryProvider)
          .savePrimaryColorArgb(opaque.toARGB32());
    }
    await ref.read(appPrimarySystemPaletteProvider.notifier).setEnabled(false);
    state = opaque;
  }

  int _validIndex(int index) =>
      index >= 0 && index < AppPrimaryPalette.colors.length ? index : 0;
}

final appPrimarySystemPaletteProvider =
    NotifierProvider<AppPrimarySystemPaletteController, bool>(
      AppPrimarySystemPaletteController.new,
    );

class AppPrimarySystemPaletteController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appSettingsRepositoryProvider).loadPrimarySystemPalette();

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .savePrimarySystemPalette(enabled);
    state = enabled;
  }
}
