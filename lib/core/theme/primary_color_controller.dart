import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';
import 'app_colors.dart';

final appPrimaryColorProvider =
    NotifierProvider<AppPrimaryColorController, int>(
      AppPrimaryColorController.new,
    );

class AppPrimaryColorController extends Notifier<int> {
  @override
  int build() {
    final stored = ref
        .watch(appSettingsRepositoryProvider)
        .loadPrimaryColorIndex(0);
    return _validIndex(stored);
  }

  Color get color => AppPrimaryPalette.colors[state];

  Future<void> setIndex(int index) async {
    final validIndex = _validIndex(index);
    if (state == validIndex) return;
    state = validIndex;
    await ref
        .read(appSettingsRepositoryProvider)
        .savePrimaryColorIndex(validIndex);
  }

  int _validIndex(int index) =>
      index >= 0 && index < AppPrimaryPalette.colors.length ? index : 0;
}
