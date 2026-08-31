import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/settings/app_settings_repository.dart';
import '../../library/domain/entities/song.dart';
import '../domain/playback_enums.dart';
import '../domain/playback_queue.dart';

/// Glue between [AudioService] (notification, background, headset buttons)
/// and [AudioPlayer]. Owns the play queue and repeat/shuffle rules so both
/// in-app actions and notification actions behave identically. Also mirrors
/// the session into [AppSettingsRepository] so it survives app restarts.
class MusicPlayerHandler extends BaseAudioHandler with SeekHandler {
  MusicPlayerHandler(this._player, {this.settings}) {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object _, StackTrace _) {},
    );
    _player.playerStateStream.listen(_onPlayerStateChanged);
    _player.positionStream.listen(_onPositionChanged);
    _initialization = _restorePersistedQueue();
  }

  static const int _maxAutoSkipsOnError = 3;
  static const int _positionSaveIntervalMs = 5000;

  final AudioPlayer _player;

  /// Persists the session across restarts; null disables persistence (tests).
  final AppSettingsRepository? settings;
  late final Future<void> _initialization;
  bool _hydratedFromStorage = false;
  final PlaybackQueue _queue = PlaybackQueue();
  RepeatMode _repeatMode = RepeatMode.off;
  int _consecutiveLoadFailures = 0;
  int _lastSavedPositionMs = -1;

  /// Emits the title of a song whose file failed to load.
  final StreamController<String> _loadErrors =
      StreamController<String>.broadcast();

  /// Bumped whenever queue composition/index/modes change so observers can
  /// re-project state without polling.
  final StreamController<int> _queueRevisions =
      StreamController<int>.broadcast();
  int _revision = 0;

  Stream<String> get loadErrors => _loadErrors.stream;

  Stream<int> get queueRevisions => _queueRevisions.stream;

  RepeatMode get repeatMode => _repeatMode;
  bool get shuffled => _queue.shuffled;
  List<Song> get queueSongs => _queue.songs;
  int get currentIndex => _queue.currentIndex;
  Song? get currentSong => _queue.current;

  /// True until the UI has had a chance to replace the lightweight snapshot
  /// with the current MediaStore metadata.
  bool get hydratedFromStorage => _hydratedFromStorage;

  void _touchQueue() {
    _revision++;
    _queueRevisions.add(_revision);
  }

  // ---------------------------------------------------------------------------
  // Session persistence
  // ---------------------------------------------------------------------------

  void _onPositionChanged(Duration position) {
    final ms = position.inMilliseconds;
    final last = _lastSavedPositionMs;
    if (!_player.playing) {
      if (ms != last && _queue.isNotEmpty) {
        _lastSavedPositionMs = ms;
        _persistSession();
      }
      return;
    }
    if ((ms - last).abs() >= _positionSaveIntervalMs) {
      _lastSavedPositionMs = ms;
      _persistSession();
    }
  }

  void _persistSession() {
    final store = settings;
    if (store == null || !_queue.isNotEmpty) return;
    store.savePlaybackSession(
      SavedPlaybackSession(
        queueSongIds: _queue.originalSongs
            .map((song) => song.id)
            .toList(growable: false),
        currentSongId: _queue.current?.id,
        positionMs: _player.position.inMilliseconds,
        repeatModeIndex: _repeatMode.index,
        shuffled: _queue.shuffled,
        tracks: _queue.originalSongs
            .map(
              (song) => SavedPlaybackTrack(
                id: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                durationMs: song.duration.inMilliseconds,
                path: song.path,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Future<void> _restorePersistedQueue() async {
    final session = settings?.loadPlaybackSession();
    if (session == null ||
        session.tracks.isEmpty ||
        session.currentSongId == null) {
      return;
    }
    final byId = {for (final track in session.tracks) track.id: track};
    final songs = <Song>[];
    for (final id in session.queueSongIds) {
      final track = byId[id];
      if (track == null) continue;
      songs.add(
        Song(
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          albumId: 0,
          artistId: 0,
          duration: Duration(milliseconds: track.durationMs),
          path: track.path,
          sizeBytes: 0,
          dateAddedSeconds: 0,
        ),
      );
    }
    final startIndex = songs.indexWhere(
      (song) => song.id == session.currentSongId,
    );
    if (songs.isEmpty || startIndex < 0) return;
    _queue.load(songs, startIndex: startIndex);
    if (session.shuffled) _queue.setShuffled(true);
    _hydratedFromStorage = true;
    _publishQueueMediaItems();
    mediaItem.add(_mediaItemFor(_queue.current!));
    _touchQueue();
    try {
      await _player.setAudioSource(AudioSource.file(_queue.current!.path));
      if (session.positionMs > 0) {
        await _player.seek(Duration(milliseconds: session.positionMs));
      }
      _broadcastState(_player.playbackEvent);
    } catch (_) {
      _queue.clear();
      _hydratedFromStorage = false;
      mediaItem.add(null);
      queue.add(const []);
      _touchQueue();
    }
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  Future<void> loadAndPlay(List<Song> songs, {int startIndex = 0}) async {
    await _initialization;
    if (songs.isEmpty) return;
    _queue.load(songs, startIndex: startIndex);
    await _loadCurrent(playImmediately: true);
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> play() async {
    await _initialization;
    if (_queue.current == null) return;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _initialization;
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _initialization;
    await _player.seek(position);
  }

  Future<void> next({bool wrap = true}) async {
    await _initialization;
    if (!_queue.isNotEmpty) return;
    if (!_queue.next(wrap: wrap)) {
      await stopAndClearQueue();
      return;
    }
    await _loadCurrent(playImmediately: true);
  }

  Future<void> previous() async {
    await _initialization;
    if (!_queue.isNotEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!_queue.previous(wrap: true)) return;
    await _loadCurrent(playImmediately: true);
  }

  Future<void> jumpTo(int index) async {
    await _initialization;
    if (!_queue.jumpTo(index)) return;
    await _loadCurrent(playImmediately: true);
  }

  void toggleShuffle() => setShuffled(!_queue.shuffled);

  void setShuffled(bool enabled) {
    _queue.setShuffled(enabled);
    _publishQueueMediaItems();
    _touchQueue();
    _persistSession();
    _broadcastState(_player.playbackEvent);
  }

  /// off -> all -> one -> off
  void cycleRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _touchQueue();
    _persistSession();
    _broadcastState(_player.playbackEvent);
  }

  /// Removes a song from the queue. If it was the playing track, playback
  /// continues with the next song automatically. Returns true when the
  /// removed song was the current one.
  Future<bool> removeSong(int songId) async {
    await _initialization;
    final currentId = _queue.current?.id;
    if (currentId != songId) {
      _queue.removeById(songId);
      _publishQueueMediaItems();
      _touchQueue();
      _persistSession();
      return false;
    }
    _queue.removeById(songId);
    if (_queue.current == null) {
      await stopAndClearQueue();
    } else {
      await _loadCurrent(playImmediately: true);
    }
    return true;
  }

  Future<void> stopAndClearQueue() async {
    await _initialization;
    _queue.clear();
    _consecutiveLoadFailures = 0;
    await settings?.clearPlaybackSession();
    try {
      await _player.stop();
    } finally {
      mediaItem.add(null);
      queue.add(const []);
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
          controls: const [],
          updatePosition: Duration.zero,
        ),
      );
      _touchQueue();
    }
  }

  /// Rebuilds a previous session paused at [position] so the user can resume
  /// exactly where the app was closed. Never starts playback.
  Future<bool> restoreSession({
    required List<Song> songs,
    required Song current,
    required Duration position,
    required RepeatMode repeatMode,
    required bool shuffled,
  }) async {
    await _initialization;
    _hydratedFromStorage = false;
    final startIndex = songs.indexWhere((song) => song.id == current.id);
    if (startIndex < 0) return false;
    _consecutiveLoadFailures = 0;
    _repeatMode = repeatMode;
    _queue.load(songs, startIndex: startIndex);
    if (shuffled) _queue.setShuffled(true);
    final restoredCurrent = _queue.current ?? current;
    _publishQueueMediaItems();
    mediaItem.add(_mediaItemFor(restoredCurrent));
    // Publish the queue before touching disk. Loading a MediaStore file can
    // take a moment; the UI and media session should already know the track.
    _touchQueue();
    try {
      await _player.setAudioSource(AudioSource.file(restoredCurrent.path));
      if (position > Duration.zero) {
        await _player.seek(position);
      }
    } catch (_) {
      _loadErrors.add(restoredCurrent.title);
      _queue.clear();
      mediaItem.add(null);
      queue.add(const []);
      _touchQueue();
      return false;
    }
    _broadcastState(_player.playbackEvent);
    return true;
  }

  /// Writes the current session snapshot to settings immediately.
  void persistSession() => _persistSession();

  @override
  Future<void> stop() => stopAndClearQueue();

  @override
  Future<void> onTaskRemoved() async {
    // Android can remove the activity while the foreground media service is
    // still alive. Save the exact position so media controls remain usable.
    _persistSession();
  }

  @override
  Future<void> skipToNext() => next();

  @override
  Future<void> skipToPrevious() => previous();

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleShuffle':
        toggleShuffle();
        return;
      case 'cycleRepeat':
        cycleRepeatMode();
        return;
      case 'closePlayer':
        await stopAndClearQueue();
        return;
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _onPlayerStateChanged(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      await _handleCompleted();
      return;
    }
    if (!state.playing) {
      // Covers manual pauses, audio-focus loss and unplug events.
      _lastSavedPositionMs = _player.position.inMilliseconds;
      _persistSession();
    }
    _broadcastState(_player.playbackEvent);
  }

  Future<void> _handleCompleted() async {
    if (_repeatMode == RepeatMode.one && _queue.current != null) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    final moved = _queue.next(wrap: _repeatMode == RepeatMode.all);
    if (!moved) {
      await _player.seek(Duration.zero);
      await _player.pause();
      _broadcastState(_player.playbackEvent);
      return;
    }
    await _loadCurrent(playImmediately: true);
  }

  Future<void> _loadCurrent({required bool playImmediately}) async {
    final song = _queue.current;
    if (song == null) {
      await stopAndClearQueue();
      return;
    }
    mediaItem.add(_mediaItemFor(song));
    _touchQueue();
    _broadcastState(_player.playbackEvent);
    try {
      await _player.setAudioSource(AudioSource.file(song.path));
      _consecutiveLoadFailures = 0;
      _lastSavedPositionMs = _player.position.inMilliseconds;
      _persistSession();
      if (playImmediately || _player.playing) {
        await _player.play();
      }
    } catch (error) {
      _consecutiveLoadFailures++;
      _loadErrors.add(song.title);
      final canSkip =
          _consecutiveLoadFailures < _maxAutoSkipsOnError &&
          _queue.currentIndex < _queue.length - 1;
      if (canSkip) {
        await next(wrap: false);
      } else {
        await _player.pause();
        _broadcastState(_player.playbackEvent);
      }
    }
  }

  MediaItem _mediaItemFor(Song song) {
    return MediaItem(
      id: 'song_${song.id}',
      title: song.title,
      album: song.album.isEmpty ? null : song.album,
      artist: song.artist.isEmpty ? null : song.artist,
      duration: song.duration > Duration.zero ? song.duration : null,
      artUri: Uri.parse(
        'content://media/external/audio/media/${song.id}/albumart',
      ),
      extras: {'path': song.path},
    );
  }

  void _publishQueueMediaItems() {
    queue.add(
      _queue.songs.map<MediaItem>(_mediaItemFor).toList(growable: false),
    );
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final hasActiveSong = _queue.current != null;
    final controls = hasActiveSong
        ? <MediaControl>[
            MediaControl.custom(
              androidIcon: shuffled
                  ? 'drawable/ic_notif_shuffle'
                  : 'drawable/ic_notif_shuffle_off',
              label: 'Shuffle',
              name: 'toggleShuffle',
            ),
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.custom(
              androidIcon: 'drawable/ic_notif_close',
              label: 'Close',
              name: 'closePlayer',
            ),
          ]
        : const <MediaControl>[];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2, 3],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
