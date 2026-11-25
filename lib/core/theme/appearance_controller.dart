import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';
import '../settings/appearance_preferences.dart';
import '../settings/photo_framing.dart';
import '../storage/appearance_image_store.dart';

final appearanceProvider =
    NotifierProvider<AppearanceController, AppearancePreferences>(
      AppearanceController.new,
    );

class AppearanceController extends Notifier<AppearancePreferences> {
  Future<void> _pendingSave = Future<void>.value();

  @override
  AppearancePreferences build() =>
      ref.watch(appSettingsRepositoryProvider).loadAppearance();

  Future<void> setSystemTheme(bool enabled) =>
      _update((current) => current.copyWith(systemTheme: enabled));
  Future<void> setBackgroundColor(int color) => _update(
    (current) => current.copyWith(backgroundColor: color | 0xff000000),
  );
  Future<void> resetBackground() =>
      _update((current) => current.copyWith(clearBackground: true));
  Future<void> setForegroundColor(int color) => _update(
    (current) => current.copyWith(foregroundColor: color | 0xff000000),
  );
  Future<void> resetForeground() =>
      _update((current) => current.copyWith(clearForeground: true));
  Future<void> setPhotoDimming(double value) =>
      _update((current) => current.copyWith(photoDimming: value));

  Future<void> setPhotoFraming(String path, PhotoFraming framing) => _update(
    (current) => current.photoPath == path
        ? current.copyWith(photoFraming: framing)
        : current,
  );

  Future<void> pickPhoto(
    Future<PhotoFraming?> Function(String path) chooseFraming,
  ) async {
    final store = ref.read(appearanceImageStoreProvider);
    final path = await store.pick();
    if (path == null) return;
    var saved = false;
    try {
      if (!ref.mounted) return;
      final framing = await chooseFraming(path);
      if (framing == null || !ref.mounted) return;
      await _update(
        (current) => current.copyWith(photoPath: path, photoFraming: framing),
      );
      saved = true;
    } finally {
      if (!saved) await store.remove(path);
    }
  }

  Future<void> _update(
    AppearancePreferences Function(AppearancePreferences) change,
  ) {
    final repository = ref.read(appSettingsRepositoryProvider);
    final store = ref.read(appearanceImageStoreProvider);
    final save = _pendingSave.then((_) async {
      if (!ref.mounted) throw StateError('Appearance controller was disposed');
      final previous = state;
      final next = change(previous);
      if (identical(next, previous)) return;
      await repository.saveAppearance(next);
      if (ref.mounted) state = next;
      if (previous.photoPath != next.photoPath) {
        await store.remove(previous.photoPath);
      }
    });
    _pendingSave = save.catchError((Object _) {});
    return save;
  }
}
