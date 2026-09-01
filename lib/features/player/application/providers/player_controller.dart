import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import '../../../../core/settings/app_settings_repository.dart';
import '../../../library/application/providers/library_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../domain/playback_enums.dart';
import '../../infrastructure/music_player_handler.dart';
import '../models/player_state.dart';
import '../session_resume.dart';

/// Injected from main(); owns the concrete AudioPlayer.
final audioPlayerProvider = Provider<AudioPlayer>(
  (ref) => throw UnimplementedError('Override audioPlayerProvider in main'),
);

/// Lazily boots the background media handler so app startup never blocks on
/// [AudioService.init]. Resolves to the handler, or a plain fallback when the
/// platform service is temporarily unavailable (e.g. right after an OS process
/// reclaim), mirroring the previous resilience in main().
final musicPlayerHandlerProvider =
    AsyncNotifierProvider<MusicPlayerBootstrap, MusicPlayerHandler>(
  MusicPlayerBootstrap.new,
);

class MusicPlayerBootstrap extends AsyncNotifier<MusicPlayerHandler> {
  @override
  Future<MusicPlayerHandler> build() async {
    final player = ref.watch(audioPlayerProvider);
    final settings = ref.watch(appSettingsRepositoryProvider);

    // Audio focus setup is best effort: a transient platform audio-session
    // failure must not prevent the library screen from opening.
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {
      // Continue with the platform defaults; playback can still be initialized.
    }

    try {
      return await AudioService.init<MusicPlayerHandler>(
        builder: () => MusicPlayerHandler(player, settings: settings),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.songs_cleaner.playback',
          androidNotificationChannelName: 'پخش موزیک',
          androidNotificationIcon: 'drawable/ic_notif_applogo',
          // Keep the media service in the foreground while paused. Android 12+
          // otherwise blocks a later media-button action when the activity has
          // been swiped away because restarting foreground service is restricted.
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
        ),
      );
    } catch (_) {
      return MusicPlayerHandler(player, settings: settings);
    }
  }
}

final playerProvider = NotifierProvider<PlayerController, PlayerState>(
  PlayerController.new,
);

/// Broadcasts titles of songs whose files failed to load, for snackbars.
final playbackErrorEventsProvider = StreamProvider<String>((ref) {
  final handler = ref.watch(musicPlayerHandlerProvider).value;
  return handler?.loadErrors ?? const Stream<String>.empty();
});

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    // Watch the async handler so this controller re-runs once the background
    // service finishes booting; playback stays inert until then.
    final handler = ref.watch(musicPlayerHandlerProvider).value;
    final player = ref.watch(audioPlayerProvider);

    final subscriptions = <StreamSubscription<dynamic>>[];

    subscriptions
      ..add(
        player.positionStream.listen((position) {
          state = state.copyWith(position: position);
        }),
      )
      ..add(
        player.bufferedPositionStream.listen((buffered) {
          state = state.copyWith(bufferedPosition: buffered);
        }),
      )
      ..add(
        player.durationStream.listen((duration) {
          state = state.copyWith(duration: duration ?? Duration.zero);
        }),
      )
      ..add(
        player.playerStateStream.listen((playerState) {
          state = state.copyWith(
            playing: playerState.playing,
            processingState: _mapProcessingState(playerState.processingState),
          );
        }),
      );

    // Mirror the handler's queue. The initial read at the end of build already
    // captures any queue a background-process restore produced before this
    // controller subscribed, and this listener covers every later change.
    if (handler != null) {
      subscriptions.add(
        handler.queueRevisions.listen((_) => _mirrorHandler(handler)),
      );
    }

    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    });

    _restoreWhenReady(handler);

    return PlayerState(
      songs: handler?.queueSongs ?? const [],
      index: handler?.currentIndex ?? -1,
      playing: false,
      repeatMode: handler?.repeatMode ?? RepeatMode.off,
      shuffled: handler?.shuffled ?? false,
      queueRevision: 0,
    );
  }

  /// Resolves to the booted handler, waiting for it if a user action fires
  /// before the background service finished starting.
  Future<MusicPlayerHandler> _handler() =>
      ref.read(musicPlayerHandlerProvider.future);

  // ---------------------------------------------------------------------------
  // Session restore
  // ---------------------------------------------------------------------------

  /// Restores the previous playback session (paused, at the last position) as
  /// soon as both the handler and the library are available, exactly once.
  ///
  /// Reads state directly at the end instead of relying only on the
  /// queueRevisions stream, so the restore is deterministic regardless of
  /// subscription timing.
  void _restoreWhenReady(MusicPlayerHandler? handler) {
    if (handler == null) return;

    var started = false;

    void onLibrary(LibraryState? library) {
      if (started || library == null || library.songs.isEmpty) return;
      started = true;
      _restoreLastSession(handler, library.songs);
    }

    final existing = ref.read(libraryProvider).value;
    if (existing != null && existing.songs.isNotEmpty) {
      started = true;
      _restoreLastSession(handler, existing.songs);
    } else {
      ref.listen(libraryProvider, (_, next) => onLibrary(next.value));
    }
  }

  Future<void> _restoreLastSession(
    MusicPlayerHandler handler,
    List<Song> librarySongs,
  ) async {
    final settings = ref.read(appSettingsRepositoryProvider);
    final session = settings.loadPlaybackSession();
    final plan = SessionResumePlanner.plan(session, librarySongs);

    // No persisted session (or the tracks are gone): surface whatever the
    // background process restored instead of leaving an empty player.
    if (plan == null) {
      _mirrorHandler(handler);
      return;
    }

    final restored = await handler.restoreSession(
      songs: plan.queue,
      current: plan.current,
      position: plan.position,
      repeatMode: plan.repeatMode,
      shuffled: plan.shuffled,
    );
    if (!restored) return;

    // Seed the seek position directly: a paused player emits no position
    // stream updates, so without this the seek bar would look wrong after
    // reopening the app.
    state = state.copyWith(
      songs: handler.queueSongs,
      index: handler.currentIndex,
      repeatMode: handler.repeatMode,
      shuffled: handler.shuffled,
      position: plan.position,
      queueRevision: state.queueRevision + 1,
    );
  }

  /// Copies the handler's current queue/modes into state (single source of
  /// truth). Safe to call multiple times; also reflects a cleared queue.
  void _mirrorHandler(MusicPlayerHandler handler) {
    state = state.copyWith(
      songs: handler.queueSongs,
      index: handler.currentIndex,
      repeatMode: handler.repeatMode,
      shuffled: handler.shuffled,
      queueRevision: state.queueRevision + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Playback actions
  // ---------------------------------------------------------------------------

  /// Starts playing [songs] beginning at [startIndex].
  Future<void> playFromList(List<Song> songs, {required int startIndex}) async {
    final handler = await _handler();
    await handler.loadAndPlay(songs, startIndex: startIndex);
  }

  /// Builds a fresh shuffled order of the whole list and starts it.
  Future<void> playAllShuffled(List<Song> songs) async {
    final handler = await _handler();
    final shuffledCopy = [...songs]..shuffle();
    await handler.loadAndPlay(shuffledCopy, startIndex: 0);
  }

  Future<void> toggleShuffle() async {
    final handler = await _handler();
    handler.toggleShuffle();
  }

  Future<void> cycleRepeatMode() async {
    final handler = await _handler();
    handler.cycleRepeatMode();
  }

  Future<void> playPause() async {
    final handler = await _handler();
    await handler.playPause();
  }

  Future<void> next() async {
    final handler = await _handler();
    await handler.next();
  }

  Future<void> previous() async {
    final handler = await _handler();
    await handler.previous();
  }

  Future<void> jumpToQueueIndex(int index) async {
    final handler = await _handler();
    await handler.jumpTo(index);
  }

  Future<void> seek(Duration position) async {
    final handler = await _handler();
    await handler.seek(position);
  }

  Future<bool> removeFromQueue(int songId) async {
    final handler = await _handler();
    return handler.removeSong(songId);
  }

  /// Stops playback and empties the queue (used by the queue sheet).
  Future<void> clearQueue() async {
    final handler = await _handler();
    await handler.stopAndClearQueue();
  }

  static PlayerProcessingState _mapProcessingState(ProcessingState source) =>
      switch (source) {
        ProcessingState.idle => PlayerProcessingState.idle,
        ProcessingState.loading => PlayerProcessingState.loading,
        ProcessingState.buffering => PlayerProcessingState.buffering,
        ProcessingState.ready => PlayerProcessingState.ready,
        ProcessingState.completed => PlayerProcessingState.completed,
      };
}
