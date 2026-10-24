import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';

void main() {
  test(
    'lock screen timeout defaults to five seconds and persists options',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = AppSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(repository.loadLockScreenTimeoutSeconds(), 5);
      for (final seconds in AppSettingsRepository.lockScreenTimeoutOptions) {
        await repository.saveLockScreenTimeoutSeconds(seconds);
        expect(repository.loadLockScreenTimeoutSeconds(), seconds);
      }
      expect(
        () => repository.saveLockScreenTimeoutSeconds(0),
        throwsArgumentError,
      );
    },
  );

  test(
    'invalid stored lock screen timeout falls back to five seconds',
    () async {
      SharedPreferences.setMockInitialValues({'lockscreen.timeoutSeconds': -1});
      final repository = AppSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(repository.loadLockScreenTimeoutSeconds(), 5);
    },
  );

  test('round-trips an atomic playback session snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);
    const session = SavedPlaybackSession(
      queueSongIds: [3, 7],
      currentSongId: 7,
      positionMs: 42100,
      repeatModeIndex: 2,
      shuffled: true,
      wasPlaying: true,
      tracks: [
        SavedPlaybackTrack(
          id: 3,
          title: 'First',
          artist: 'Artist',
          album: 'Album',
          durationMs: 100000,
          path: '/music/first.mp3',
        ),
        SavedPlaybackTrack(
          id: 7,
          title: 'Current',
          artist: 'Artist',
          album: 'Album',
          durationMs: 200000,
          path: '/music/current.mp3',
        ),
      ],
    );

    await repository.savePlaybackSession(session);

    final restored = repository.loadPlaybackSession();

    expect(restored, isNotNull);
    expect(restored!.queueSongIds, [3, 7]);
    expect(restored.currentSongId, 7);
    expect(restored.positionMs, 42100);
    expect(restored.repeatModeIndex, 2);
    expect(restored.shuffled, isTrue);
    expect(restored.wasPlaying, isTrue);
    expect(restored.tracks.map((track) => track.path), [
      '/music/first.mp3',
      '/music/current.mp3',
    ]);
  });

  test('loads sessions saved by the legacy multi-key format', () async {
    SharedPreferences.setMockInitialValues({
      'playback.session.queueIds': ['11'],
      'playback.session.currentId': 11,
      'playback.session.positionMs': 900,
      'playback.session.repeatIndex': 1,
      'playback.session.shuffled': false,
      'playback.session.tracks':
          '[{"id":11,"title":"Legacy","artist":"Artist",'
          '"album":"Album","durationMs":1000,"path":"/legacy.mp3"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    final restored = repository.loadPlaybackSession();

    expect(restored, isNotNull);
    expect(restored!.currentSongId, 11);
    expect(restored.positionMs, 900);
    expect(restored.tracks.single.path, '/legacy.mp3');
    expect(restored.wasPlaying, isFalse);
  });

  test('round-trips the lock-screen controls toggle', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadLockScreenEnabled(false), isFalse);

    await repository.saveLockScreenEnabled(true);
    expect(repository.loadLockScreenEnabled(false), isTrue);

    await repository.saveLockScreenEnabled(false);
    expect(repository.loadLockScreenEnabled(true), isFalse);
  });

  test('round-trips the previous-goes-to-previous toggle', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadPreviousGoesToPrevious(false), isFalse);

    await repository.savePreviousGoesToPrevious(true);
    expect(repository.loadPreviousGoesToPrevious(false), isTrue);

    await repository.savePreviousGoesToPrevious(false);
    expect(repository.loadPreviousGoesToPrevious(true), isFalse);
  });

  test('quick delete remains visible by default and can be hidden', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadHideQuickDelete(false), isFalse);

    await repository.saveHideQuickDelete(true);
    expect(repository.loadHideQuickDelete(false), isTrue);
  });

  test('round-trips the appearance theme mode', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadThemeMode('dark'), 'dark');

    await repository.saveThemeMode('light');
    expect(repository.loadThemeMode('dark'), 'light');
  });

  test('round-trips the primary color selection', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadPrimaryColorIndex(0), 0);

    await repository.savePrimaryColorIndex(7);
    expect(repository.loadPrimaryColorIndex(0), 7);
  });

  test('round-trips the app locale', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadLocale('system'), 'system');

    await repository.saveLocale('fa');
    expect(repository.loadLocale('system'), 'fa');
  });

  test('round-trips and clamps playback speed', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadPlaybackSpeed(1), 1);

    await repository.savePlaybackSpeed(1.5);
    expect(repository.loadPlaybackSpeed(1), 1.5);

    await repository.savePlaybackSpeed(9);
    expect(repository.loadPlaybackSpeed(1), 3);
  });

  test('migrates the legacy playlists tab index to the new layout', () async {
    SharedPreferences.setMockInitialValues({'home.tabIndex': 3});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadHomeTabIndex(0), 5);

    await repository.saveHomeTabIndex(3);
    expect(repository.loadHomeTabIndex(0), 3);
  });

  test('round-trips equalizer settings', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadEqualizerEnabled(false), isFalse);
    expect(repository.loadEqualizerGains(), isEmpty);

    await repository.saveEqualizerEnabled(true);
    await repository.saveEqualizerGains([-3.5, 0, 4.25]);

    expect(repository.loadEqualizerEnabled(false), isTrue);
    expect(repository.loadEqualizerGains(), [-3.5, 0, 4.25]);
  });

  test('round-trips audio focus mode index', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadAudioFocusMode(0), 0);
    await repository.saveAudioFocusMode(1);
    expect(repository.loadAudioFocusMode(0), 1);
  });

  test('round-trips gapless playback preference', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(preferences);

    expect(repository.loadGaplessPlayback(false), isFalse);
    await repository.saveGaplessPlayback(true);
    expect(repository.loadGaplessPlayback(false), isTrue);
  });
}
