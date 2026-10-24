import 'package:flutter/material.dart';
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
    return AppPrimaryPalette.colors[_validIndex(settings.loadPrimaryColorIndex(0))];
  }

  Future<void> setColor(Color color) async {
    final opaque = color.withAlpha(255);
    if (state == opaque) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .savePrimaryColorArgb(opaque.toARGB32());
    state = opaque;
  }

  int _validIndex(int index) =>
      index >= 0 && index < AppPrimaryPalette.colors.length ? index : 0;
}
