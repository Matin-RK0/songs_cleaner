import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/theme/app_colors.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/theme/primary_color_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> createContainer(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('preserves every previously saved palette selection', () async {
    for (var index = 0; index < AppPrimaryPalette.colors.length; index++) {
      final container = await createContainer({
        'appearance.primaryColorIndex': index,
      });
      expect(
        container.read(appPrimaryColorProvider),
        AppPrimaryPalette.colors[index],
      );
    }
  });

  test('invalid stored index falls back to the default', () async {
    final container = await createContainer({
      'appearance.primaryColorIndex': -1,
    });
    expect(
      container.read(appPrimaryColorProvider),
      AppPrimaryPalette.colors.first,
    );
  });

  test(
    'custom color persists and overrides the legacy palette index',
    () async {
      final container = await createContainer({
        'appearance.primaryColorIndex': 2,
      });
      await container
          .read(appPrimaryColorProvider.notifier)
          .setColor(const Color(0xff123456));

      expect(container.read(appPrimaryColorProvider), const Color(0xff123456));
      expect(
        container.read(appSettingsRepositoryProvider).loadPrimaryColorArgb(),
        0xff123456,
      );
      container.invalidate(appPrimaryColorProvider);
      expect(container.read(appPrimaryColorProvider), const Color(0xff123456));
    },
  );

  test('keeps theme colors opaque', () async {
    final container = await createContainer({});
    await container
        .read(appPrimaryColorProvider.notifier)
        .setColor(const Color(0x00123456));
    expect(container.read(appPrimaryColorProvider), const Color(0xff123456));
  });

  test('custom primary is used by both theme modes', () {
    const color = Color(0xff123456);
    expect(AppTheme.light(primary: color).colorScheme.primary, color);
    expect(AppTheme.dark(primary: color).colorScheme.primary, color);
  });
}
