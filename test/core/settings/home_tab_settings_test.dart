import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/settings/home_tab_settings.dart';
import 'package:songs_cleaner/core/settings/home_tab_settings_controller.dart';

void main() {
  test('moving tabs in either direction preserves the chosen start tab', () {
    final original = const HomeTabSettings().withDefault(HomeTab.playlists);
    final reordered = original.reordered(3, 0).reordered(1, 4);

    expect(reordered.order, [
      HomeTab.playlists,
      HomeTab.artists,
      HomeTab.albums,
      HomeTab.telegram,
      HomeTab.songs,
    ]);
    expect(reordered.order.indexOf(reordered.defaultTab), 0);
    expect(original.order, HomeTab.values);
  });

  test(
    'unknown, duplicate and missing stored tabs recover a complete layout',
    () {
      final settings = HomeTabSettings.fromJson({
        'order': ['playlists', 'removed-tab', 'playlists', null],
        'defaultTab': 'removed-tab',
      });

      expect(settings.order.first, HomeTab.playlists);
      expect(settings.order.toSet(), HomeTab.values.toSet());
      expect(settings.order.length, HomeTab.values.length);
      expect(settings.defaultTab, HomeTab.songs);
    },
  );

  test('order and start tab survive a new provider container', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(first.dispose);
    final settings = const HomeTabSettings()
        .reordered(3, 0)
        .reordered(1, 4)
        .withDefault(HomeTab.telegram);

    await first.read(homeTabSettingsProvider.notifier).save(settings);
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);

    final restored = restarted.read(homeTabSettingsProvider);
    expect(restored.order, settings.order);
    expect(restored.defaultTab, HomeTab.telegram);
  });

  test('corrupt stored snapshot falls back to a usable default', () async {
    SharedPreferences.setMockInitialValues({'home.tabSettings': '{broken'});
    final repository = AppSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final settings = repository.loadHomeTabSettings();
    expect(settings.order, HomeTab.values);
    expect(settings.defaultTab, HomeTab.songs);
  });
}
