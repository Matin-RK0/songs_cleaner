import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import '../../../../core/settings/app_settings_repository.dart';
import '../../../library/application/providers/library_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../domain/playback_enums.dart';
import '../../infrastructure/music_player_handler.dart';
import '../models/player_state.dart';

/// Injected from main() after AudioService.init().
final audioPlayerProvider = Provider<AudioPlayer>(
  (ref) => throw UnimplementedError('Override audioPlayerProvider in main'),
);

/// Injected from main() after AudioService.init().
final musicPlayerHandlerProvider = Provider<MusicPlayerHandler>(
  (ref) => throw UnimplementedError('Override musicPlayerHandlerProvider in main'),
);

final playerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// Broadcasts titles of songs whose files failed to load, for snackbars.
final playbackErrorEventsProvider = StreamProvider<String>(
  (ref) => ref.watch(musicPlayerHandlerProvider).loadErrors,
);

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    final handler = ref.watch(musicPlayerHandlerProvider);
    final player = ref.watch(audioPlayerProvider);
    final subscriptions = <StreamSubscription<dynamic>>[];

    subscriptions
      ..add(player.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }))
      ..add(player.bufferedPositionStream.listen((buffered) {
        state = state.copyWith(bufferedPosition: buffered);
      }))
      ..add(player.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      }))
      ..add(player.playerStateStream.listen((playerState) {
        state = state.copyWith(
          playing: playerState.playing,
          processingState: _mapProcessingState(playerState.processingState),
        );
      }))
      ..add(handler.queueRevisions.listen((_) {
        state = state.copyWith(
          songs: handler.queueSongs,
          index: handler.currentIndex,
          shuffled: handler.shuffled,
          repeatMode: handler.repeatMode,
          queueRevision: state.queueRevision + 1,
        );
      }));

    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    });

    _scheduleSessionRestore();

    return PlayerState(
      songs: handler.queueSongs,
      index: handler.currentIndex,
      playing: false,
      repeatMode: handler.repeatMode,
      shuffled: handler.shuffled,
      queueRevision: 0,
    );
  }

  MusicPlayerHandler get _handler => ref.read(musicPlayerHandlerProvider);

  // ---------------------------------------------------------------------------
  // Session restore
  // ---------------------------------------------------------------------------

  /// Restores the previous playback session (paused, at the last position)
  /// exactly once, as soon as the library is available. Listens instead of
  /// watching so library refreshes never rebuild the player.
  void _scheduleSessionRestore() {
    var attempted = false;

    void tryRestore(LibraryState? library) {
      if (attempted || library == null || library.songs.isEmpty) return;
      attempted = true;
      if (_handler.queueSongs.isNotEmpty) return;
      _restoreLastSession(library.songs);
    }

    final existing = ref.read(libraryProvider);
    tryRestore(existing.value);
    ref.listen(libraryProvider, (_, next) => tryRestore(next.value));
  }

  Future<void> _restoreLastSession(List<Song> librarySongs) async {
    final settings = ref.read(appSettingsRepositoryProvider);
    final session = settings.loadPlaybackSession();
    if (session == null || !session.isRestorable) return;

    final byId = {for (final song in librarySongs) song.id: song};
    final queue = [
      for (final id in session.queueSongIds)
        if (byId[id] != null) byId[id]!,
    ];
    final current = byId[session.currentSongId];
    if (current == null || queue.isEmpty) return;

    final repeatIndex =
        session.repeatModeIndex.clamp(0, RepeatMode.values.length - 1);
    await _handler.restoreSession(
      songs: queue,
      current: current,
      position: Duration(milliseconds: session.positionMs),
      repeatMode: RepeatMode.values[repeatIndex],
      shuffled: session.shuffled,
    );
  }

  /// Starts playing [songs] beginning at [startIndex].
  Future<void> playFromList(List<Song> songs, {required int startIndex}) =>
      _handler.loadAndPlay(songs, startIndex: startIndex);

  /// Builds a fresh shuffled order of the whole list and starts it.
  Future<void> playAllShuffled(List<Song> songs) {
    final shuffledCopy = [...songs]..shuffle();
    return _handler.loadAndPlay(shuffledCopy, startIndex: 0);
  }

  Future<void> toggleShuffle() async {
    _handler.toggleShuffle();
  }

  void cycleRepeatMode() => _handler.cycleRepeatMode();

  Future<void> playPause() => _handler.playPause();

  Future<void> next() => _handler.next();

  Future<void> previous() => _handler.previous();

  Future<void> jumpToQueueIndex(int index) => _handler.jumpTo(index);

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<bool> removeFromQueue(int songId) => _handler.removeSong(songId);

  /// Stops playback and empties the queue (used by the queue sheet).
  Future<void> clearQueue() => _handler.stopAndClearQueue();

  static PlayerProcessingState _mapProcessingState(ProcessingState source) =>
      switch (source) {
        ProcessingState.idle => PlayerProcessingState.idle,
        ProcessingState.loading => PlayerProcessingState.loading,
        ProcessingState.buffering => PlayerProcessingState.buffering,
        ProcessingState.ready => PlayerProcessingState.ready,
        ProcessingState.completed => PlayerProcessingState.completed,
      };
}
