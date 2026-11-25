import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/storage/appearance_image_store.dart';
import 'package:songs_cleaner/core/theme/appearance_controller.dart';
import 'package:songs_cleaner/core/theme/system_palette_controller.dart';
import 'package:songs_cleaner/core/widgets/appearance_photo.dart';
import 'package:songs_cleaner/features/lockscreen/presentation/widgets/appearance_customization_tiles.dart';

void main() {
  testWidgets(
    'gallery, dimming preview and system mode work in a narrow RTL layout',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.binding.setSurfaceSize(const Size(340, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final directory = Directory.systemTemp.createTempSync(
          'appearance-frame-test-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final photo =
            File('${directory.path}${Platform.pathSeparator}gallery.png')
              ..writeAsBytesSync(
                base64Decode(
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                ),
              );
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            appearanceImageStoreProvider.overrideWithValue(
              _Gallery(photo.path),
            ),
            systemPaletteProvider.overrideWith(
              (ref) async => (
                light: const ColorScheme.light(),
                dark: const ColorScheme.dark(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('fa'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: AppearanceCustomizationTiles(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(
            FileImage(photo),
            tester.element(find.byType(Scaffold)),
          ),
        );
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
        await tester.tap(find.text(l10n.appBackgroundTitle));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.appBackgroundPhoto));
        await tester.pumpAndSettle();
        expect(container.read(appearanceProvider).photoPath, isNull);
        expect(find.text(l10n.photoFramingInstructions), findsOneWidget);
        tester.widget<Slider>(find.byType(Slider)).onChanged!(2);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(FramedAppearancePhoto),
          const Offset(-35, 25),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.saveAction));
        await tester.pumpAndSettle();
        expect(container.read(appearanceProvider).photoPath, photo.path);
        expect(container.read(appearanceProvider).photoFraming.zoom, 2);
        expect(
          container.read(appearanceProvider).photoFraming.x,
          greaterThan(0.5),
        );
        await tester.tap(find.text(l10n.appBackgroundDimming));
        await tester.pumpAndSettle();
        final slider = find.byType(Slider);
        tester.widget<Slider>(slider).onChanged!(0.9);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l10n.saveAction));
        await tester.tap(find.text(l10n.saveAction));
        await tester.pumpAndSettle();
        expect(container.read(appearanceProvider).photoDimming, 0.9);

        await tester.tap(find.text(l10n.fullSystemThemeTitle));
        await tester.pumpAndSettle();
        expect(container.read(appearanceProvider).systemTheme, isTrue);
        final background = find.widgetWithText(
          ListTile,
          l10n.appBackgroundTitle,
        );
        expect(tester.widget<ListTile>(background).enabled, isFalse);
        await tester.tap(find.text(l10n.fullSystemThemeTitle));
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(background).enabled, isTrue);
        expect(container.read(appearanceProvider).photoPath, photo.path);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

class _Gallery extends AppearanceImageStore {
  const _Gallery(this.path);

  final String path;

  @override
  Future<String?> pick() async => path;
}
