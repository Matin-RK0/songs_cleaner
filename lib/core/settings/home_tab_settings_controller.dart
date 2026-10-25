import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_repository.dart';
import 'home_tab_settings.dart';

final homeTabSettingsProvider =
    NotifierProvider<HomeTabSettingsController, HomeTabSettings>(
      HomeTabSettingsController.new,
    );

class HomeTabSettingsController extends Notifier<HomeTabSettings> {
  @override
  HomeTabSettings build() =>
      ref.watch(appSettingsRepositoryProvider).loadHomeTabSettings();

  Future<void> save(HomeTabSettings settings) async {
    await ref.read(appSettingsRepositoryProvider).saveHomeTabSettings(settings);
    state = settings;
  }
}
