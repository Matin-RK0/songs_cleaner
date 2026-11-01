import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
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
  ProcessingState get processingState => ProcessingState.ready;
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
    playing = true;
    await playbackCompletion?.future;
  }

  @override
  Future<void> pause() async {
    await pausing?.future;
    playing = false;
  }

  Future<void> close() async {
    await events.close();
    await states.close();
    await positions.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
