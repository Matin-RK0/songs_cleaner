import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../core/settings/app_settings_repository.dart';
import '../../library/domain/entities/song.dart';
import '../../library/infrastructure/data_sources/device_music_data_source.dart';
import '../domain/playback_enums.dart';
import '../domain/audio_focus_mode.dart';
import '../domain/playback_queue.dart';

/// Glue between [AudioService] (notification, background, headset buttons)
/// and [AudioPlayer]. Owns the play queue and repeat/shuffle rules so both
/// in-app actions and notification actions behave identically. Also mirrors
/// the session into [AppSettingsRepository] so it survives app restarts.
class MusicPlayerHandler extends BaseAudioHandler with SeekHandler {
  MusicPlayerHandler(this._player, {this.settings, this.mediaCatalog}) {
    _player.playbackEventStream.listen((event) {
      if (_gaplessEnabled) _onPlaylistIndexChanged(_player.currentIndex);
      _broadcastState(event);
    }, onError: (Object _, StackTrace _) {});
    _player.playerStateStream.listen(_onPlayerStateChanged);
    _player.positionStream.listen(_onPositionChanged);
    _gaplessEnabled = settings?.loadGaplessPlayback(false) ?? false;
    _initialization = _restorePersistedQueue();
    final savedSpeed = settings?.loadPlaybackSpeed(1) ?? 1;
    _player.setSpeed(savedSpeed);
    _listenToAudioFocus();
    _player.currentIndexStream.listen(_onPlaylistIndexChanged);
  }

  static const int _maxAutoSkipsOnError = 3;
  static const int _positionSaveIntervalMs = 5000;

  final AudioPlayer _player;

  /// Persists the session across restarts; null disables persistence (tests).
  final AppSettingsRepository? settings;
  final Future<List<MediaItem>> Function(String parentId)? mediaCatalog;
  late final Future<void> _initialization;
  bool _hydratedFromStorage = false;
  final PlaybackQueue _queue = PlaybackQueue();
  RepeatMode _repeatMode = RepeatMode.off;
  int _consecutiveLoadFailures = 0;
  int _lastSavedPositionMs = -1;
  bool _closing = false;
  bool _gaplessEnabled = false;
  bool _loadingGaplessSources = false;
  Duration? _pendingPosition;
  int _sourceRevision = 0;
  bool _wasPlayingBeforeInterruption = false;
  double? _volumeBeforeDucking;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  Future<void> _sessionWrite = Future<void>.value();

  /// Emits the title of a song whose file failed to load.
  final StreamController<String> _loadErrors =
      StreamController<String>.broadcast();

  /// Bumped whenever queue composition/index/modes change so observers can
  /// re-project state without polling.
  final StreamController<int> _queueRevisions =
      StreamController<int>.broadcast();
  int _revision = 0;

  final StreamController<Duration?> _sleepTimerChanges =
      StreamController<Duration?>.broadcast();

  Stream<String> get loadErrors => _loadErrors.stream;

  Stream<int> get queueRevisions => _queueRevisions.stream;

  Stream<Duration?> get sleepTimerChanges => _sleepTimerChanges.stream;

  Duration? get sleepTimerRemaining {
    final end = _sleepTimerEnd;
    if (end == null) return null;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _listenToAudioFocus() async {
    final session = await AudioSession.instance;
    _interruptionSubscription = session.interruptionEventStream.listen(
      _handleInterruption,
    );
    _noisySubscription = session.becomingNoisyEventStream.listen((_) {
      if (_focusMode != AudioFocusMode.ignore) pause();
    });
  }

  AudioFocusMode get _focusMode {
    final index = settings
        ?.loadAudioFocusMode(AudioFocusMode.pause.index)
        .clamp(0, AudioFocusMode.values.length - 1);
    return AudioFocusMode.values[index ?? AudioFocusMode.pause.index];
  }

  void _handleInterruption(AudioInterruptionEvent event) {
    final mode = _focusMode;
    if (mode == AudioFocusMode.ignore) return;
    if (event.begin) {
      if (mode == AudioFocusMode.duck) {
        if (_player.playing) {
          _volumeBeforeDucking = _player.volume;
          _player.setVolume(_player.volume * 0.5);
        }
        return;
      }
      _wasPlayingBeforeInterruption = _player.playing;
      if (_wasPlayingBeforeInterruption) pause();
      return;
    }
    if (mode == AudioFocusMode.duck) {
      final volume = _volumeBeforeDucking;
      _volumeBeforeDucking = null;
      if (volume != null) _player.setVolume(volume);
    } else if (_wasPlayingBeforeInterruption) {
      _wasPlayingBeforeInterruption = false;
      play();
    }
  }

  void _onPlaylistIndexChanged(int? index) {
    if (!_gaplessEnabled || _loadingGaplessSources || index == null) return;
    if (_pendingPosition != null || index != _player.currentIndex) return;
    if (index < 0 || index >= _queue.length) return;
    if (_queue.currentIndex == index &&
        mediaItem.value?.id == 'song_${_queue.current?.id}') {
      return;
    }
    if (!_queue.jumpTo(index)) return;
    final song = _queue.current;
    if (song == null) return;
    mediaItem.add(_mediaItemFor(song));
    _broadcastState(_player.playbackEvent);
    _touchQueue();
    _persistSession();
  }

  RepeatMode get repeatMode => _repeatMode;
  bool get shuffled => _queue.shuffled;
  bool get gapless => _gaplessEnabled;
  List<Song> get queueSongs => _queue.songs;
  int get currentIndex => _queue.currentIndex;
  Song? get currentSong => _queue.current;

  bool get isChangingSource => _pendingPosition != null;

  /// Never combine a new track's duration with the outgoing source's clock.
  Duration get position => _queue.current == null
      ? Duration.zero
      : _pendingPosition ?? _player.position;
  Duration get duration {
    final song = _queue.current;
    if (song == null) return Duration.zero;
    if (isChangingSource) return song.duration;
    return _player.duration ?? song.duration;
  }

  Duration get bufferedPosition => isChangingSource || _queue.current == null
      ? Duration.zero
      : _player.bufferedPosition;

  int _beginSourceChange({Duration position = Duration.zero}) {
    _pendingPosition = position;
    final revision = ++_sourceRevision;
    _broadcastState(_player.playbackEvent);
    final song = _queue.current;
    if (song != null) mediaItem.add(_mediaItemFor(song));
    _touchQueue();
    return revision;
  }

  void _finishSourceChange(int revision) {
    if (revision != _sourceRevision) return;
    _pendingPosition = null;
    _broadcastState(_player.playbackEvent);
  }

  /// Refresh restored metadata without reloading audio or reshuffling the queue.
  Future<bool> refreshRestoredMetadata(List<Song> songs) async {
    await _initialization;
    if (_queue.current == null) return false;
    if (_hydratedFromStorage) {
      _queue.refreshMetadata(songs);
      _hydratedFromStorage = false;
      _publishQueueMediaItems();
      mediaItem.add(_mediaItemFor(_queue.current!));
      _touchQueue();
    }
    return true;
  }

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
    if (isChangingSource) return;
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

  Future<void> _persistSession() {
    final store = settings;
    if (store == null || !_queue.isNotEmpty) return Future<void>.value();
    final snapshot = SavedPlaybackSession(
      queueSongIds: _queue.originalSongs
          .map((song) => song.id)
          .toList(growable: false),
      currentSongId: _queue.current?.id,
      positionMs: position.inMilliseconds,
      repeatModeIndex: _repeatMode.index,
      shuffled: _queue.shuffled,
      wasPlaying: _player.playing,
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
    );
    return _enqueueSessionWrite(() => store.savePlaybackSession(snapshot));
  }

  Future<void> _clearPersistedSession() {
    final store = settings;
    if (store == null) return Future<void>.value();
    return _enqueueSessionWrite(store.clearPlaybackSession);
  }

  Future<void> _enqueueSessionWrite(Future<void> Function() write) {
    _sessionWrite = _sessionWrite
        .catchError((Object _) {})
        .then((_) => write())
        .catchError((Object _) {});
    return _sessionWrite;
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
    _repeatMode = RepeatMode
        .values[session.repeatModeIndex.clamp(0, RepeatMode.values.length - 1)];
    _queue.load(songs, startIndex: startIndex);
    if (session.shuffled) _queue.setShuffled(true);
    _hydratedFromStorage = true;
    _publishQueueMediaItems();
    final revision = _beginSourceChange(
      position: Duration(milliseconds: session.positionMs),
    );
    try {
      if (_gaplessEnabled) {
        await _loadGaplessSources(
          position: Duration(milliseconds: session.positionMs),
          playImmediately: false,
        );
      } else {
        await _player.setAudioSource(
          AudioSource.file(_queue.current!.path),
          initialPosition: Duration(milliseconds: session.positionMs),
        );
      }
      _broadcastState(_player.playbackEvent);
    } catch (_) {
      _queue.clear();
      _hydratedFromStorage = false;
      mediaItem.add(null);
      queue.add(const []);
      _touchQueue();
      await _clearPersistedSession();
    } finally {
      _finishSourceChange(revision);
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

  Future<void> _loadGaplessSources({
    Duration position = Duration.zero,
    required bool playImmediately,
  }) async {
    if (_queue.current == null) return;
    final revision = _beginSourceChange(position: position);
    _loadingGaplessSources = true;
    try {
      await _player.setAudioSources(
        _queue.songs.map((song) => AudioSource.file(song.path)).toList(),
        initialIndex: _queue.currentIndex,
        initialPosition: position,
      );
    } finally {
      _loadingGaplessSources = false;
      _finishSourceChange(revision);
    }
    _publishQueueMediaItems();
    mediaItem.add(_mediaItemFor(_queue.current!));
    _touchQueue();
    await _persistSession();
    if (playImmediately) await _player.play();
  }

  Future<void> setGaplessPlayback(bool enabled) async {
    await _initialization;
    _gaplessEnabled = enabled;
    await settings?.saveGaplessPlayback(enabled);
    if (_queue.current != null) {
      if (enabled) {
        await _loadGaplessSources(
          position: _player.position,
          playImmediately: _player.playing,
        );
      } else {
        final wasPlaying = _player.playing;
        final position = _player.position;
        final revision = _beginSourceChange(position: position);
        try {
          await _player.setAudioSource(
            AudioSource.file(_queue.current!.path),
            initialPosition: position,
          );
        } finally {
          _finishSourceChange(revision);
        }
        if (wasPlaying) await _player.play();
      }
    }
    _broadcastState(_player.playbackEvent);
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
    if (_queue.current == null) {
      final newestSong = await DeviceMusicDataSource(
        OnAudioQuery(),
      ).fetchNewestExistingSong();
      if (newestSong == null) return;
      _queue.load([newestSong]);
      await _loadCurrent(playImmediately: true);
      return;
    }
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
    if (isChangingSource) return;
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _initialization;
    final normalized = speed.clamp(0.5, 3.0).toDouble();
    await _player.setSpeed(normalized);
    await settings?.savePlaybackSpeed(normalized);
    _broadcastState(_player.playbackEvent);
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimerEnd = duration == null ? null : DateTime.now().add(duration);
    _sleepTimerChanges.add(duration);
    if (duration == null) return;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = sleepTimerRemaining;
      if (remaining == null) {
        timer.cancel();
        return;
      }
      if (remaining <= Duration.zero) {
        timer.cancel();
        _sleepTimerEnd = null;
        _sleepTimerChanges.add(null);
        await pause();
        return;
      }
      _sleepTimerChanges.add(remaining);
    });
  }

  Future<void> next({bool wrap = true}) async {
    await _initialization;
    if (!_queue.isNotEmpty) return;
    if (!_queue.next(wrap: wrap)) {
      await stopAndClearQueue();
      return;
    }
    if (_gaplessEnabled) {
      await _seekToCurrent();
    } else {
      await _loadCurrent(playImmediately: true);
    }
  }

  Future<void> previous() async {
    await _initialization;
    if (!_queue.isNotEmpty) return;
    final goToPrevious = settings?.loadPreviousGoesToPrevious(false) ?? false;
    if (!goToPrevious && _player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!_queue.previous(wrap: true)) return;
    if (_gaplessEnabled) {
      await _seekToCurrent();
    } else {
      await _loadCurrent(playImmediately: true);
    }
  }

  Future<void> jumpTo(int index) async {
    await _initialization;
    if (!_queue.jumpTo(index)) return;
    if (_gaplessEnabled) {
      await _seekToCurrent();
    } else {
      await _loadCurrent(playImmediately: true);
    }
  }

  Future<void> toggleShuffle() => setShuffled(!_queue.shuffled);

  Future<void> _seekToCurrent() async {
    final revision = _beginSourceChange();
    try {
      await _player.seek(Duration.zero, index: _queue.currentIndex);
      await _persistSession();
    } finally {
      _finishSourceChange(revision);
    }
  }

  Future<void> setShuffled(bool enabled) async {
    _queue.setShuffled(enabled);
    if (_gaplessEnabled && _queue.current != null) {
      await _loadGaplessSources(
        position: _player.position,
        playImmediately: _player.playing,
      );
      return;
    }
    _publishQueueMediaItems();
    _touchQueue();
    _persistSession();
    _broadcastState(_player.playbackEvent);
  }

  /// off -> all -> one -> off
  Future<void> cycleRepeatMode() async {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _touchQueue();
    _persistSession();
    await _applyLoopMode();
    _broadcastState(_player.playbackEvent);
  }

  Future<void> _applyLoopMode() async {
    await _player.setLoopMode(switch (_repeatMode) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _initialization;
    _repeatMode = switch (repeatMode) {
      AudioServiceRepeatMode.one => RepeatMode.one,
      AudioServiceRepeatMode.all => RepeatMode.all,
      _ => RepeatMode.off,
    };
    _touchQueue();
    await _persistSession();
    await _applyLoopMode();
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _initialization;
    await setShuffled(shuffleMode != AudioServiceShuffleMode.none);
  }

  /// Removes a song from the queue. If it was the playing track, playback
  /// continues with the next song automatically. Returns true when the
  /// removed song was the current one.
  Future<bool> removeSong(int songId) async {
    await _initialization;
    final currentId = _queue.current?.id;
    if (currentId != songId) {
      _queue.removeById(songId);
      if (_gaplessEnabled && _queue.current != null) {
        await _loadGaplessSources(
          position: _player.position,
          playImmediately: _player.playing,
        );
        return false;
      }
      _publishQueueMediaItems();
      _touchQueue();
      _persistSession();
      return false;
    }
    _queue.removeById(songId);
    if (_queue.current == null) {
      await stopAndClearQueue();
    } else if (_gaplessEnabled) {
      await _loadGaplessSources(playImmediately: true);
    } else {
      await _loadCurrent(playImmediately: true);
    }
    return true;
  }

  Future<bool> addToQueue(Song song) async {
    await _initialization;
    final changed = _queue.addToEnd(song);
    if (!changed) return false;
    if (_gaplessEnabled) {
      await _loadGaplessSources(
        position: _player.position,
        playImmediately: _player.playing,
      );
      return true;
    }
    _publishQueueMediaItems();
    _touchQueue();
    await _persistSession();
    return true;
  }

  Future<bool> playNextSong(Song song) async {
    await _initialization;
    final wasEmpty = !_queue.isNotEmpty;
    final changed = _queue.playNext(song);
    if (!changed) return false;
    if (_gaplessEnabled) {
      await _loadGaplessSources(
        position: _player.position,
        playImmediately: _player.playing,
      );
      if (wasEmpty) await _player.pause();
      return true;
    }
    _publishQueueMediaItems();
    _touchQueue();
    await _persistSession();
    if (wasEmpty) await _loadCurrent(playImmediately: false);
    return true;
  }

  Future<bool> reorderQueue(int oldIndex, int newIndex) async {
    await _initialization;
    final changed = _queue.reorder(oldIndex, newIndex);
    if (!changed) return false;
    if (_gaplessEnabled) {
      await _loadGaplessSources(
        position: _player.position,
        playImmediately: _player.playing,
      );
      return true;
    }
    _publishQueueMediaItems();
    _touchQueue();
    await _persistSession();
    return true;
  }

  Future<void> stopAndClearQueue() async {
    await _initialization;
    _queue.clear();
    _pendingPosition = null;
    _sourceRevision++;
    _consecutiveLoadFailures = 0;
    await _clearPersistedSession();
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
    await _applyLoopMode();
    _queue.load(songs, startIndex: startIndex);
    if (shuffled) _queue.setShuffled(true);
    final restoredCurrent = _queue.current ?? current;
    _publishQueueMediaItems();
    // Publish the queue before touching disk. Loading a MediaStore file can
    // take a moment; the UI and media session should already know the track.
    final revision = _beginSourceChange(position: position);
    try {
      if (_gaplessEnabled) {
        await _loadGaplessSources(position: position, playImmediately: false);
      } else {
        await _player.setAudioSource(
          AudioSource.file(restoredCurrent.path),
          initialPosition: position,
        );
      }
    } catch (_) {
      _loadErrors.add(restoredCurrent.title);
      _queue.clear();
      mediaItem.add(null);
      queue.add(const []);
      _touchQueue();
      return false;
    } finally {
      _finishSourceChange(revision);
    }
    _broadcastState(_player.playbackEvent);
    return true;
  }

  /// Writes the current session snapshot to settings immediately.
  Future<void> persistSession() => _persistSession();

  /// Fully closes the app from the media notification's close control.
  ///
  /// The paused queue and position are persisted first so the next launch can
  /// resume exactly where the user left off, then the media notification and
  /// foreground services are torn down and the Android task is finished.
  Future<void> closeApp() async {
    if (_closing) return;
    _closing = true;
    _sleepTimer?.cancel();
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
    await _player.pause();
    await _persistSession();
    // Clearing the media item and publishing an idle state removes the media
    // notification and releases the audio service, while leaving the persisted
    // session (and the in-memory queue) untouched.
    mediaItem.add(null);
    queue.add(const []);
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: const [],
      ),
    );
    await super.stop();
  }

  @override
  Future<void> stop() => stopAndClearQueue();

  @override
  Future<void> onTaskRemoved() async {
    // Android can remove the activity while the foreground media service is
    // still alive. Save the exact position so media controls remain usable.
    await _persistSession();
  }

  Future<void> onAudioFocusLost() async {
    await pause();
  }

  @override
  Future<void> skipToNext() => next();

  @override
  Future<void> skipToPrevious() => previous();

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final id = int.tryParse(mediaItem.id.replaceFirst('song_', ''));
    if (id == null) return;
    final index = _queue.songs.indexWhere((song) => song.id == id);
    if (index < 0) {
      final songs = await DeviceMusicDataSource(OnAudioQuery()).fetchSongs();
      final songIndex = songs.indexWhere((song) => song.id == id);
      if (songIndex < 0) return;
      await loadAndPlay(songs, startIndex: songIndex);
      return;
    }
    await loadAndPlay(_queue.songs, startIndex: index);
  }

  /// Exposes the current queue to Android Auto and other media browsers.
  /// The app has no remote catalog, so the queue is the stable browsable root.
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (parentMediaId == 'root' && mediaCatalog != null) {
      return mediaCatalog!('root');
    }
    if (parentMediaId == AudioService.recentRootId ||
        parentMediaId == 'queue') {
      return _queue.songs.map(_mediaItemFor).toList(growable: false);
    }
    return mediaCatalog == null
        ? const <MediaItem>[]
        : mediaCatalog!(parentMediaId);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleShuffle':
        await toggleShuffle();
        return;
      case 'cycleRepeat':
        await cycleRepeatMode();
        return;
      case 'closePlayer':
        await closeApp();
        return;
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _onPlayerStateChanged(PlayerState state) async {
    if (isChangingSource) {
      _broadcastState(_player.playbackEvent);
      return;
    }
    if (state.processingState == ProcessingState.completed &&
        _player.processingState == ProcessingState.completed) {
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
    if (_gaplessEnabled) {
      try {
        await _loadGaplessSources(playImmediately: playImmediately);
        _consecutiveLoadFailures = 0;
      } catch (error) {
        _consecutiveLoadFailures++;
        _loadErrors.add(song.title);
      }
      return;
    }
    final revision = _beginSourceChange();
    try {
      await _player.setAudioSource(AudioSource.file(song.path));
      if (revision != _sourceRevision) return;
      _finishSourceChange(revision);
      _consecutiveLoadFailures = 0;
      _lastSavedPositionMs = _player.position.inMilliseconds;
      await _persistSession();
      if (playImmediately || _player.playing) {
        await _player.play();
      }
    } catch (error) {
      if (revision != _sourceRevision) return;
      _finishSourceChange(revision);
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
    // The bare media URI resolves album art on Android 10+ through
    // ContentResolver.loadThumbnail. `loadThumbnailUri` must be non-null so
    // audio_service picks that path instead of the removed `/albumart` legacy
    // URI, otherwise the notification shows no artwork.
    final mediaUri = song.id >= 0
        ? 'content://media/external/audio/media/${song.id}'
        : null;
    return MediaItem(
      id: 'song_${song.id}',
      title: song.title,
      playable: true,
      album: song.album.isEmpty ? null : song.album,
      artist: song.artist.isEmpty ? null : song.artist,
      duration: song.duration > Duration.zero ? song.duration : null,
      artUri: mediaUri == null ? null : Uri.parse(mediaUri),
      extras: {'path': song.path, 'loadThumbnailUri': ?mediaUri},
    );
  }

  void _publishQueueMediaItems() {
    queue.add(
      _queue.songs.map<MediaItem>(_mediaItemFor).toList(growable: false),
    );
  }

  void _broadcastState(PlaybackEvent event) {
    // Once the user closes the app, keep the state idle so no listener revives
    // the notification during the shutdown sequence.
    if (_closing) return;
    final playing = _player.playing;
    final hasActiveSong = _queue.current != null;
    final controls = hasActiveSong
        ? <MediaControl>[
            MediaControl.custom(
              androidIcon: shuffled
                  ? 'drawable/ic_notif_shuffle'
                  : 'drawable/ic_notif_shuffle_off',
              label: _localizedLabel('Shuffle', 'پخش تصادفی'),
              name: 'toggleShuffle',
            ),
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.custom(
              androidIcon: 'drawable/ic_notif_close',
              label: _localizedLabel('Close', 'بستن'),
              name: 'closePlayer',
            ),
          ]
        : const <MediaControl>[];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2, 3],
        processingState: isChangingSource
            ? AudioProcessingState.loading
            : switch (_player.processingState) {
                ProcessingState.idle => AudioProcessingState.idle,
                ProcessingState.loading => AudioProcessingState.loading,
                ProcessingState.buffering => AudioProcessingState.buffering,
                ProcessingState.ready => AudioProcessingState.ready,
                ProcessingState.completed => AudioProcessingState.completed,
              },
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: _player.speed,
        repeatMode: switch (_repeatMode) {
          RepeatMode.off => AudioServiceRepeatMode.none,
          RepeatMode.all => AudioServiceRepeatMode.all,
          RepeatMode.one => AudioServiceRepeatMode.one,
        },
        shuffleMode: shuffled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        queueIndex: _queue.currentIndex < 0 ? null : _queue.currentIndex,
      ),
    );
  }

  String _localizedLabel(String english, String persian) {
    final stored =
        settings?.loadLocale(Platform.localeName) ?? Platform.localeName;
    final language = stored == 'system'
        ? Platform.localeName.split(RegExp('[-_]')).first
        : stored.split(RegExp('[-_]')).first;
    return language == 'fa' ? persian : english;
  }
}
