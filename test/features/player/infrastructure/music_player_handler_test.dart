import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/infrastructure/music_player_handler.dart';

Song _song(int id, int seconds) => Song(
  id: id,
  title: 'Track $id',
  artist: 'Artist',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(seconds: seconds),
  path: '/$id.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Player extends Fake implements AudioPlayer {
  final events = StreamController<PlaybackEvent>.broadcast();
  final states = StreamController<PlayerState>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  Completer<void>? loading;
  Completer<void>? pausing;
  Completer<void>? playbackCompletion;
  int playCalls = 0;
  @override
  int? currentIndex = 0;
  @override
  Duration position = Duration.zero;
  @override
  Duration? duration = const Duration(seconds: 300);
  @override
  bool playing = false;
  @override
  double get speed => 1;
  @override
  Duration get bufferedPosition => position;
  @override
  ProcessingState processingState = ProcessingState.ready;
  @override
  PlaybackEvent get playbackEvent => PlaybackEvent(
    processingState: processingState,
    updatePosition: position,
    bufferedPosition: bufferedPosition,
    duration: duration,
  );
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await loading?.future;
    position = initialPosition ?? Duration.zero;
    duration = const Duration(seconds: 60);
    return duration;
  }

  @override
  Future<void> play() async {
    playCalls++;
    playing = true;
    await playbackCompletion?.future;
  }

  @override
  Future<void> pause() async {
    await pausing?.future;
    playing = false;
  }

  @override
  Future<void> stop() async {
    playing = false;
    processingState = ProcessingState.idle;
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex = 0,
    Duration? initialPosition = Duration.zero,
    ShuffleOrder? shuffleOrder,
  }) async {
    currentIndex = initialIndex;
    return setAudioSource(
      sources[initialIndex ?? 0],
      initialPosition: initialPosition,
    );
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    this.position = position ?? Duration.zero;
    if (index != null) currentIndex = index;
  }

  Future<void> close() async {
    await events.close();
    await states.close();
    await positions.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit cold Play builds a complete fallback queue', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(
      player,
      loadFallbackSongs: () async => [_song(1, 60), _song(2, 60)],
    );
    addTearDown(player.close);
    expect(player.playCalls, 0);
    await handler.play();
    expect(handler.queueSongs.map((song) => song.id), [1, 2]);
    expect(handler.currentSong?.id, 1);
    await handler.next();
    expect(handler.currentSong?.id, 2);
    await handler.closeApp();
  });

  test('a newer selection supersedes a slow cold-library fallback', () async {
    final library = Completer<List<Song>>();
    final player = _Player();
    final handler = MusicPlayerHandler(
      player,
      loadFallbackSongs: () => library.future,
    );
    addTearDown(player.close);
    final coldPlay = handler.play();
    await Future<void>.delayed(Duration.zero);
    await handler.loadAndPlay([_song(3, 60), _song(4, 60)]);
    library.complete([_song(1, 60), _song(2, 60)]);
    await coldPlay;
    expect(handler.queueSongs.map((song) => song.id), [3, 4]);
    expect(handler.currentSong?.id, 3);
    expect(player.playCalls, 1);
    await handler.closeApp();
  });

  test(
    'reserving a download does not interrupt an in-flight song selection',
    () async {
      final player = _Player()..loading = Completer<void>();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      final selecting = handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
      await Future<void>.delayed(Duration.zero);
      final request = handler.reservePlaybackRequest();
      player.loading!.complete();
      await selecting;
      expect(player.playing, isTrue);
      expect(handler.currentSong?.id, 1);
      expect(
        await handler.playRequestedSong(_song(3, 60), request: request),
        isTrue,
      );
      expect(handler.currentSong?.id, 3);
      // A fulfilled request is consumed, even if a callback is delivered twice.
      expect(
        await handler.playRequestedSong(_song(3, 60), request: request),
        isFalse,
      );
      await handler.closeApp();
    },
  );

  test('empty fallback library does not start playback', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(
      player,
      loadFallbackSongs: () async => [],
    );
    addTearDown(player.close);
    await handler.play();
    expect(handler.queueSongs, isEmpty);
    expect(player.playCalls, 0);
    await handler.closeApp();
  });

  test(
    'single-track transport is a no-op and not advertised to media clients',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60)]);
      player.position = const Duration(seconds: 20);
      await handler.next();
      await handler.previous();
      expect(handler.canSkipTracks, isFalse);
      expect(player.position, const Duration(seconds: 20));
      expect(player.playCalls, 1);
      expect(
        handler.playbackState.value.controls,
        isNot(contains(MediaControl.skipToNext)),
      );
      expect(
        handler.playbackState.value.controls,
        isNot(contains(MediaControl.skipToPrevious)),
      );
      expect(handler.playbackState.value.androidCompactActionIndices, [1]);
      await handler.closeApp();
    },
  );

  for (final gapless in [false, true]) {
    test(
      'download selection preserves the active queue, gapless=$gapless',
      () async {
        SharedPreferences.setMockInitialValues({});
        final settings = AppSettingsRepository(
          await SharedPreferences.getInstance(),
        );
        await settings.saveGaplessPlayback(gapless);
        final player = _Player();
        final handler = MusicPlayerHandler(player, settings: settings);
        addTearDown(player.close);
        await handler.loadAndPlay([_song(1, 60), _song(2, 60), _song(3, 60)]);
        final request = handler.reservePlaybackRequest();
        expect(
          await handler.playRequestedSong(_song(4, 60), request: request),
          isTrue,
        );
        expect(handler.queueSongs.map((song) => song.id), [1, 4, 2, 3]);
        expect(handler.currentSong?.id, 4);
        await handler.next();
        expect(handler.currentSong?.id, 2);
        await handler.previous();
        expect(handler.currentSong?.id, 4);
        await handler.closeApp();
      },
    );
  }

  test(
    'download already present selects its original slot without reordering',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60), _song(2, 60), _song(3, 60)]);
      final request = handler.reservePlaybackRequest();
      await handler.playRequestedSong(_song(3, 60), request: request);
      expect(handler.queueSongs.map((song) => song.id), [1, 2, 3]);
      expect(handler.currentSong?.id, 3);
      await handler.closeApp();
    },
  );

  test('download with no prior queue uses the available library', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(player);
    addTearDown(player.close);
    final request = handler.reservePlaybackRequest();
    await handler.playRequestedSong(
      _song(3, 60),
      request: request,
      fallbackSongs: [_song(1, 60), _song(2, 60), _song(3, 60)],
    );
    expect(handler.queueSongs.map((song) => song.id), [1, 2, 3]);
    expect(handler.currentSong?.id, 3);
    await handler.closeApp();
  });

  for (final action in [
    'select',
    'pause',
    'next',
    'previous',
    'seek',
    'clear',
    'close',
    'play',
  ]) {
    test('a later $action supersedes pending download playback', () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
      final request = handler.reservePlaybackRequest();
      switch (action) {
        case 'select':
          await handler.loadAndPlay([_song(5, 60), _song(6, 60)]);
        case 'pause':
          await handler.pause();
        case 'next':
          await handler.next();
        case 'previous':
          await handler.previous();
        case 'seek':
          await handler.seek(const Duration(seconds: 10));
        case 'clear':
          await handler.stopAndClearQueue();
        case 'close':
          await handler.closeApp();
        case 'play':
          await handler.play();
      }
      final queue = handler.queueSongs;
      final current = handler.currentSong;
      final plays = player.playCalls;
      expect(
        await handler.playRequestedSong(_song(4, 60), request: request),
        isFalse,
      );
      expect(handler.queueSongs, queue);
      expect(handler.currentSong, current);
      expect(player.playCalls, plays);
      await handler.closeApp();
    });
  }

  test(
    'latest download-and-play request wins regardless of finish order',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
      final first = handler.reservePlaybackRequest();
      final second = handler.reservePlaybackRequest();
      expect(
        await handler.playRequestedSong(_song(3, 60), request: first),
        isFalse,
      );
      expect(
        await handler.playRequestedSong(_song(4, 60), request: second),
        isTrue,
      );
      expect(handler.currentSong?.id, 4);
      await handler.closeApp();
    },
  );

  test(
    'pause during deferred source loading prevents a late autoplay',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
      final request = handler.reservePlaybackRequest();
      player.loading = Completer<void>();
      final selecting = handler.playRequestedSong(
        _song(3, 60),
        request: request,
      );
      await Future<void>.delayed(Duration.zero);
      await handler.pause();
      player.loading!.complete();
      expect(await selecting, isFalse);
      expect(player.playing, isFalse);
      expect(player.playCalls, 1);
      await handler.closeApp();
    },
  );

  for (final gapless in [false, true]) {
    for (final wasPlaying in [false, true]) {
      test(
        'startup restores paused even if wasPlaying=$wasPlaying, gapless=$gapless',
        () async {
          SharedPreferences.setMockInitialValues({});
          final settings = AppSettingsRepository(
            await SharedPreferences.getInstance(),
          );
          await settings.saveGaplessPlayback(gapless);
          await settings.savePlaybackSession(
            SavedPlaybackSession(
              queueSongIds: const [1],
              currentSongId: 1,
              positionMs: 23000,
              repeatModeIndex: 0,
              shuffled: false,
              wasPlaying: wasPlaying,
              tracks: const [
                SavedPlaybackTrack(
                  id: 1,
                  title: 'Track 1',
                  artist: 'Artist',
                  album: '',
                  durationMs: 60000,
                  path: '/1.mp3',
                ),
              ],
            ),
          );
          final player = _Player();
          final handler = MusicPlayerHandler(player, settings: settings);
          addTearDown(player.close);
          await handler.refreshRestoredMetadata([_song(1, 60)]);

          expect(handler.currentSong?.id, 1);
          expect(player.position, const Duration(seconds: 23));
          expect(player.playing, isFalse);
          expect(player.playCalls, 0);
          expect(handler.playbackState.value.playing, isFalse);

          // Opening/recreating the UI may refresh metadata again, not play.
          await handler.refreshRestoredMetadata([_song(1, 60)]);
          expect(player.playCalls, 0);
          await handler.play();
          expect(player.playing, isTrue);
          expect(player.playCalls, 1);
          await handler.closeApp();
        },
      );
    }
  }

  test(
    'paused EOF event never advances the queue or starts playback',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
      await handler.pause();
      final playCalls = player.playCalls;
      player.processingState = ProcessingState.completed;
      player.states.add(PlayerState(false, ProcessingState.completed));
      await Future<void>.delayed(Duration.zero);

      expect(handler.currentSong?.id, 1);
      expect(player.playing, isFalse);
      expect(player.playCalls, playCalls);
      await handler.closeApp();
    },
  );

  test('active EOF still advances playback normally', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(player);
    addTearDown(player.close);
    await handler.loadAndPlay([_song(1, 60), _song(2, 60)]);
    player.processingState = ProcessingState.completed;
    player.states.add(PlayerState(true, ProcessingState.completed));
    await Future<void>.delayed(Duration.zero);

    expect(handler.currentSong?.id, 2);
    expect(player.playing, isTrue);
    expect(player.playCalls, 2);
    await handler.closeApp();
  });

  test(
    'cold media play waits for saved source and resumes without a UI',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      await settings.savePlaybackSession(
        const SavedPlaybackSession(
          queueSongIds: [1],
          currentSongId: 1,
          positionMs: 23000,
          repeatModeIndex: 0,
          shuffled: false,
          tracks: [
            SavedPlaybackTrack(
              id: 1,
              title: 'Track 1',
              artist: 'Artist',
              album: '',
              durationMs: 60000,
              path: '/1.mp3',
            ),
          ],
        ),
      );
      final player = _Player()..loading = Completer<void>();
      final handler = MusicPlayerHandler(player, settings: settings);
      addTearDown(player.close);

      final play = handler.click(MediaButton.media);
      await Future<void>.delayed(Duration.zero);
      expect(player.playing, isFalse);
      player.loading!.complete();
      await play;

      expect(player.playing, isTrue);
      expect(player.position, const Duration(seconds: 23));
      expect(handler.mediaItem.value?.id, 'song_1');
      expect(handler.playbackState.value.playing, isTrue);
      expect(
        handler.playbackState.value.controls,
        contains(MediaControl.pause),
      );
      await handler.closeApp();
    },
  );

  for (final next in [true, false]) {
    test(
      'widget ${next ? 'next' : 'previous'} reactivates a closed handler',
      () async {
        final player = _Player();
        final handler = MusicPlayerHandler(player);
        addTearDown(player.close);
        await handler.loadAndPlay([
          _song(1, 60),
          _song(2, 60),
        ], startIndex: next ? 0 : 1);
        await handler.closeApp();

        if (next) {
          await handler.skipToNext();
        } else {
          await handler.skipToPrevious();
        }
        player.events.add(player.playbackEvent);
        await Future<void>.delayed(Duration.zero);

        expect(player.playing, isTrue);
        expect(handler.playbackState.value.playing, isTrue);
        expect(handler.mediaItem.value?.id, next ? 'song_2' : 'song_1');
        await handler.closeApp();
      },
    );
  }

  test(
    'notification close removes native notification after publishing idle',
    () async {
      final player = _Player();
      var dismissals = 0;
      late final MusicPlayerHandler handler;
      handler = MusicPlayerHandler(
        player,
        dismissNotification: () async {
          dismissals++;
          expect(player.playing, isFalse);
          expect(handler.mediaItem.value, isNull);
          expect(handler.queue.value, isEmpty);
          expect(
            handler.playbackState.value.processingState,
            AudioProcessingState.idle,
          );
          expect(handler.playbackState.value.controls, isEmpty);
        },
      );
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60)]);
      player.position = const Duration(seconds: 23);

      await handler.customAction('closePlayer');
      await handler.customAction('closePlayer');
      expect(dismissals, 1);

      player.events.add(player.playbackEvent);
      await Future<void>.delayed(Duration.zero);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
      await handler.play();
      expect(player.position, const Duration(seconds: 23));
      expect(handler.mediaItem.value?.id, 'song_1');
      await handler.customAction('closePlayer');
      expect(dismissals, 2);
    },
  );

  test(
    'headset play after close restores metadata and playing state',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60)]);
      player.position = const Duration(seconds: 23);
      await handler.closeApp();

      // Match just_audio: play() does not complete until playback ends.
      player.playbackCompletion = Completer<void>();
      final resumed = handler.click(MediaButton.media);
      await Future<void>.delayed(Duration.zero);

      expect(player.playing, isTrue);
      expect(player.position, const Duration(seconds: 23));
      expect(handler.mediaItem.value?.id, 'song_1');
      expect(handler.queue.value.map((item) => item.id), ['song_1']);
      expect(handler.playbackState.value.playing, isTrue);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.ready,
      );
      expect(
        handler.playbackState.value.controls,
        contains(MediaControl.pause),
      );

      player.playbackCompletion!.complete();
      await resumed;
      await handler.click(MediaButton.media);
      player.states.add(PlayerState(false, ProcessingState.ready));
      await Future<void>.delayed(Duration.zero);
      expect(handler.playbackState.value.playing, isFalse);
      expect(handler.playbackState.value.controls, contains(MediaControl.play));

      await handler.closeApp();
      expect(handler.mediaItem.value, isNull);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    },
  );

  test('headset play waits for an in-flight close before resuming', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(player);
    addTearDown(player.close);
    await handler.loadAndPlay([_song(1, 60)]);
    player.pausing = Completer<void>();

    final closing = handler.closeApp();
    final resumed = handler.play();
    await Future<void>.delayed(Duration.zero);
    player.pausing!.complete();
    await closing;
    await resumed;

    expect(player.playing, isTrue);
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.mediaItem.value?.id, 'song_1');
  });

  test('selecting a track after close reactivates state updates', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(player);
    addTearDown(player.close);
    await handler.loadAndPlay([_song(1, 60)]);
    await handler.closeApp();

    await handler.loadAndPlay([_song(2, 60)]);
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);

    expect(handler.mediaItem.value?.id, 'song_2');
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.controls, contains(MediaControl.pause));
  });

  test(
    'close clears notification state and ignores late playback events',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 60)]);
      player.position = const Duration(seconds: 23);

      await handler.customAction('closePlayer');
      player.events.add(player.playbackEvent);
      player.states.add(PlayerState(false, ProcessingState.completed));
      player.positions.add(player.position);
      await Future<void>.delayed(Duration.zero);

      expect(player.playing, isFalse);
      expect(player.position, const Duration(seconds: 23));
      expect(handler.currentSong?.id, 1);
      expect(handler.mediaItem.value, isNull);
      expect(handler.queue.value, isEmpty);
      final state = handler.playbackState.value;
      expect(state.processingState, AudioProcessingState.idle);
      expect(state.playing, isFalse);
      expect(state.controls, isEmpty);
      expect(state.systemActions, isEmpty);
      expect(state.androidCompactActionIndices, isEmpty);

      await handler.customAction('closePlayer');
      expect(handler.playbackState.value, same(state));
    },
  );

  test(
    'notification uses the loaded duration instead of library metadata',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 300)]);

      expect(handler.mediaItem.value?.duration, const Duration(seconds: 60));

      player.duration = const Duration(seconds: 58);
      player.events.add(player.playbackEvent);
      await Future<void>.delayed(Duration.zero);
      expect(handler.mediaItem.value?.duration, const Duration(seconds: 58));
    },
  );

  test('notification clock drift is corrected without play/pause', () async {
    final player = _Player();
    final handler = MusicPlayerHandler(player);
    addTearDown(player.close);
    await handler.loadAndPlay([_song(1, 60)]);
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);

    // Playback keeps advancing without another playback event.
    player.position = const Duration(seconds: 55);
    player.positions.add(player.position);
    await Future<void>.delayed(Duration.zero);

    expect(handler.playbackState.value.updatePosition, player.position);
    expect(handler.playbackState.value.playing, isTrue);

    // Ordinary position ticks must not continuously republish media state.
    final synchronized = handler.playbackState.value;
    player.position = synchronized.position;
    player.positions.add(player.position);
    await Future<void>.delayed(Duration.zero);
    expect(handler.playbackState.value, same(synchronized));

    // Also correct a clock that is ahead of the actual audio.
    player.position = const Duration(seconds: 10);
    player.positions.add(player.position);
    await Future<void>.delayed(Duration.zero);
    expect(handler.playbackState.value.updatePosition, player.position);
  });

  test(
    'new metadata never carries the outgoing position while loading',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 300), _song(2, 60)]);
      player.position = const Duration(seconds: 240);
      player.duration = const Duration(seconds: 300);
      player.loading = Completer<void>();

      final change = handler.next();
      await Future<void>.delayed(Duration.zero);

      expect(handler.currentSong?.id, 2);
      expect(handler.mediaItem.value?.id, 'song_2');
      expect(handler.position, Duration.zero);
      expect(handler.duration, const Duration(seconds: 60));
      expect(handler.bufferedPosition, Duration.zero);
      expect(handler.playbackState.value.updatePosition, Duration.zero);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.loading,
      );

      // Late events from the outgoing source must remain masked.
      player.events.add(player.playbackEvent);
      player.positions.add(player.position);
      await Future<void>.delayed(Duration.zero);
      expect(handler.playbackState.value.updatePosition, Duration.zero);
      expect(handler.mediaItem.value?.duration, const Duration(seconds: 60));

      player.loading!.complete();
      await change;
      expect(handler.isChangingSource, isFalse);
      expect(handler.position, Duration.zero);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.ready,
      );
    },
  );

  test(
    'library arrival preserves an already active source and position',
    () async {
      final player = _Player();
      final handler = MusicPlayerHandler(player);
      addTearDown(player.close);
      await handler.loadAndPlay([_song(1, 300)]);
      player.position = const Duration(seconds: 42);
      // Would never complete if hydration attempted to load the source again.
      player.loading = Completer<void>();

      expect(await handler.refreshRestoredMetadata([_song(1, 300)]), isTrue);
      expect(handler.position, const Duration(seconds: 42));
      expect(player.playing, isTrue);
      expect(handler.isChangingSource, isFalse);
    },
  );
}
