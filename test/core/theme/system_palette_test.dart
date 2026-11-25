import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/theme/primary_color_controller.dart';
import 'package:songs_cleaner/core/theme/system_palette_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses Android light and dark roles, including the paired foreground',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('com.example.songs_cleaner/system_palette');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'light': {
            'primary': 0xff4b3691.toSigned(32),
            'onPrimary': -1,
            'surface': 0xfffafafa.toSigned(32),
          },
          'dark': {
            'primary': 0xffcdbdff.toSigned(32),
            'onPrimary': 0xff332063.toSigned(32),
            'tertiary': 0xffffbdea.toSigned(32),
          },
        },
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final palette = (await container.read(systemPaletteProvider.future))!;
      final light = AppTheme.light(systemScheme: palette.light);
      final dark = AppTheme.dark(systemScheme: palette.dark).colorScheme;
      expect(light.colorScheme.primary, const Color(0xff4b3691));
      expect(light.colorScheme.onPrimary, const Color(0xffffffff));
      expect(light.scaffoldBackgroundColor, const Color(0xfffafafa));
      expect(dark.primary, const Color(0xffcdbdff));
      expect(dark.onPrimary, const Color(0xff332063));
      expect(dark.tertiary, const Color(0xffffbdea));
    },
  );

  test('keeps the manual color and lets saving it exit system mode', () async {
    const manual = Color(0xff214365);
    SharedPreferences.setMockInitialValues({
      'appearance.primaryColorArgb': manual.toARGB32(),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final system = container.read(appPrimarySystemPaletteProvider.notifier);
    expect(container.read(appPrimarySystemPaletteProvider), isFalse);
    await system.setEnabled(true);
    expect(AppSettingsRepository(prefs).loadPrimarySystemPalette(), isTrue);
    expect(container.read(appPrimaryColorProvider), manual);
    await container.read(appPrimaryColorProvider.notifier).setColor(manual);
    expect(container.read(appPrimarySystemPaletteProvider), isFalse);
    expect(AppSettingsRepository(prefs).loadPrimarySystemPalette(), isFalse);
  });
}
