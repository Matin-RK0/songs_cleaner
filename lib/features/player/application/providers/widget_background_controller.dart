import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../infrastructure/now_playing_widget_service.dart';

final widgetBackgroundColorProvider =
    NotifierProvider<WidgetBackgroundColorController, int?>(
      WidgetBackgroundColorController.new,
    );

final widgetSystemPaletteProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsRepositoryProvider).loadWidgetSystemPalette(),
);

class WidgetBackgroundColorController extends Notifier<int?> {
  @override
  int? build() =>
      ref.watch(appSettingsRepositoryProvider).loadWidgetBackgroundColor();

  Future<void> setColor(int? value) async {
    final color = value == null ? null : (value & 0x00ffffff) | 0xff000000;
    final settings = ref.read(appSettingsRepositoryProvider);
    final previous = state;
    final wasSystem = settings.loadWidgetSystemPalette();
    await settings.saveWidgetBackgroundColor(color);
    try {
      if (wasSystem) await settings.saveWidgetSystemPalette(false);
      await const NowPlayingWidgetService().setBackgroundColor(color);
    } catch (_) {
      await settings.saveWidgetBackgroundColor(previous);
      if (wasSystem) await settings.saveWidgetSystemPalette(true);
      rethrow;
    }
    state = color;
    ref.invalidate(widgetSystemPaletteProvider);
  }

  Future<void> useSystemPalette() async {
    final settings = ref.read(appSettingsRepositoryProvider);
    if (settings.loadWidgetSystemPalette()) return;
    await settings.saveWidgetSystemPalette(true);
    try {
      await const NowPlayingWidgetService().useSystemPalette();
    } catch (_) {
      await settings.saveWidgetSystemPalette(false);
      rethrow;
    }
    ref.invalidate(widgetSystemPaletteProvider);
  }
}
