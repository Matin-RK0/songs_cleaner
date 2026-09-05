import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';

void main() {
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
}
