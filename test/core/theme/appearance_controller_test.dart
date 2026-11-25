import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/settings/appearance_preferences.dart';
import 'package:songs_cleaner/core/settings/photo_framing.dart';
import 'package:songs_cleaner/core/storage/appearance_image_store.dart';
import 'package:songs_cleaner/core/theme/app_colors.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';

import 'package:songs_cleaner/core/theme/appearance_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late SharedPreferences prefs;
  late _Images images;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    images = _Images();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appearanceImageStoreProvider.overrideWithValue(images),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('gallery cancellation keeps a custom color; replacing and resetting removes old copies', () async {
    final controller = container.read(appearanceProvider.notifier);
    await controller.setBackgroundColor(0x00224466);
    await controller.pickPhoto(_frame);
    expect(container.read(appearanceProvider).backgroundColor, 0xff224466);
    images.next = '/photos/first.jpg';
    await controller.pickPhoto(_frame);
    expect(container.read(appearanceProvider).backgroundColor, isNull);
    images.next = '/photos/second.jpg';
    await controller.pickPhoto(_frame);
    expect(images.removed, ['/photos/first.jpg']);
    await controller.resetBackground();
    expect(images.removed, ['/photos/first.jpg', '/photos/second.jpg']);
    expect(
      AppSettingsRepository(prefs).loadAppearance().backgroundKind,
      AppBackgroundKind.standard,
    );
  });

  test('system mode keeps independent choices and concurrent updates are persisted', () async {
    final controller = container.read(appearanceProvider.notifier);
    images.next = '/photos/gallery.jpg';
    await controller.pickPhoto(_frame);
    await Future.wait([
      controller.setForegroundColor(0xffefded0),
      controller.setPhotoDimming(-1),
      controller.setSystemTheme(true),
    ]);
    final saved = AppSettingsRepository(prefs).loadAppearance();
    expect(saved.photoPath, '/photos/gallery.jpg');
    expect(
      saved.photoFraming.toJson(),
      const PhotoFraming(x: 0.25, zoom: 2).toJson(),
    );
    expect(saved.foregroundColor, 0xffefded0);
    expect(saved.photoDimming, AppearancePreferences.minDimming);
    expect(saved.systemTheme, isTrue);
    await controller.setSystemTheme(false);
    expect(
      container.read(appearanceProvider).backgroundKind,
      AppBackgroundKind.photo,
    );
    expect(images.removed, isEmpty);
  });

  test('cancelling the crop deletes only the staged photo', () async {
    final controller = container.read(appearanceProvider.notifier);
    images.next = '/photos/current.jpg';
    await controller.pickPhoto(_frame);
    images.next = '/photos/staged.jpg';
    await controller.pickPhoto((_) async => null);
    expect(container.read(appearanceProvider).photoPath, '/photos/current.jpg');
    expect(images.removed, ['/photos/staged.jpg']);
    await controller.setPhotoFraming(
      '/photos/staged.jpg',
      const PhotoFraming(zoom: 3),
    );
    expect(container.read(appearanceProvider).photoFraming.zoom, 2);
  });

  test('custom background and foreground retain readable contrast', () {
    final theme = AppTheme.dark(
      appearance: const AppearancePreferences(
        backgroundColor: 0xff757575,
        foregroundColor: 0xff757575,
      ),
    );
    final tokens = theme.extension<AppColorTokens>()!;
    for (final background in [
      tokens.background,
      tokens.surface,
      tokens.surfaceHigh,
      tokens.surfaceElevated,
    ]) {
      final text = tokens.textHigh.computeLuminance() + 0.05;
      final panel = background.computeLuminance() + 0.05;
      expect(
        text > panel ? text / panel : panel / text,
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(theme.scaffoldBackgroundColor, const Color(0xff757575));
    expect(theme.textTheme.bodyMedium?.color, tokens.textHigh);
  });

  test('photo uses a transparent scaffold unless full system colors take precedence', () {
    const custom = AppearancePreferences(photoPath: '/photos/background.jpg');
    final base = AppTheme.light();
    final photo = AppTheme.light(appearance: custom);
    final system = AppTheme.light(
      appearance: custom,
      systemScheme: base.colorScheme,
    );
    expect(photo.scaffoldBackgroundColor.a, 0);
    expect(system.scaffoldBackgroundColor, base.colorScheme.surface);
  });
}

Future<PhotoFraming> _frame(String _) async =>
    const PhotoFraming(x: 0.25, zoom: 2);

class _Images extends AppearanceImageStore {
  String? next;
  final removed = <String>[];

  @override
  Future<String?> pick() async => next;

  @override
  Future<void> remove(String? path) async {
    if (path != null) removed.add(path);
  }
}
