import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../infrastructure/now_playing_widget_service.dart';

final widgetBackgroundColorProvider =
    NotifierProvider<WidgetBackgroundColorController, int?>(
      WidgetBackgroundColorController.new,
    );

class WidgetBackgroundColorController extends Notifier<int?> {
  @override
  int? build() =>
      ref.watch(appSettingsRepositoryProvider).loadWidgetBackgroundColor();

  Future<void> setColor(int? value) async {
    final color = value == null ? null : (value & 0x00ffffff) | 0xff000000;
    final settings = ref.read(appSettingsRepositoryProvider);
    final previous = state;
    await settings.saveWidgetBackgroundColor(color);
    try {
      await const NowPlayingWidgetService().setBackgroundColor(color);
    } catch (_) {
      await settings.saveWidgetBackgroundColor(previous);
      rethrow;
    }
    state = color;
  }
}
