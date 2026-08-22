import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../library/domain/entities/song.dart';
import '../domain/playback_enums.dart';
import '../domain/playback_queue.dart';

/// Glue between [AudioService] (notification, background, headset buttons)
/// and [AudioPlayer]. Owns the play queue and repeat/shuffle rules so both
/// in-app actions and notification actions behave identically.
class MusicPlayerHandler extends BaseAudioHandler with SeekHandler {
  MusicPlayerHandler(this._player) {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object _, StackTrace _) {},
    );
    _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  static const int _maxAutoSkipsOnError = 3;

  final AudioPlayer _player;
  final PlaybackQueue _queue = PlaybackQueue();
  RepeatMode _repeatMode = RepeatMode.off;
  int _consecutiveLoadFailures = 0;

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

  void _touchQueue() {
    _revision++;
    _queueRevisions.add(_revision);
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  Future<void> loadAndPlay(List<Song> songs, {int startIndex = 0}) async {
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
    if (_queue.current == null) return;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next({bool wrap = true}) async {
    if (!_queue.isNotEmpty) return;
    if (!_queue.next(wrap: wrap)) {
      await stopAndClearQueue();
      return;
    }
    await _loadCurrent(playImmediately: true);
  }

  Future<void> previous() async {
    if (!_queue.isNotEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!_queue.previous(wrap: true)) return;
    await _loadCurrent(playImmediately: true);
  }

  Future<void> jumpTo(int index) async {
    if (!_queue.jumpTo(index)) return;
    await _loadCurrent(playImmediately: true);
  }

  void toggleShuffle() => setShuffled(!_queue.shuffled);

  void setShuffled(bool enabled) {
    _queue.setShuffled(enabled);
    _publishQueueMediaItems();
    _touchQueue();
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
    _broadcastState(_player.playbackEvent);
  }

  /// Removes a song from the queue. If it was the playing track, playback
  /// continues with the next song automatically. Returns true when the
  /// removed song was the current one.
  Future<bool> removeSong(int songId) async {
    final currentId = _queue.current?.id;
    if (currentId != songId) {
      _queue.removeById(songId);
      _publishQueueMediaItems();
      _touchQueue();
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
    _queue.clear();
    _consecutiveLoadFailures = 0;
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

  @override
  Future<void> stop() => stopAndClearQueue();

  @override
  Future<void> skipToNext() => next();

  @override
  Future<void> skipToPrevious() => previous();

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleShuffle':
        toggleShuffle();
      case 'cycleRepeat':
        cycleRepeatMode();
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
      if (playImmediately || _player.playing) {
        await _player.play();
      }
    } catch (error) {
      _consecutiveLoadFailures++;
      _loadErrors.add(song.title);
      final canSkip = _consecutiveLoadFailures < _maxAutoSkipsOnError &&
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
      duration:
          song.duration > Duration.zero ? song.duration : null,
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
              androidIcon: switch (_repeatMode) {
                RepeatMode.off => 'drawable/ic_notif_repeat_off',
                RepeatMode.all => 'drawable/ic_notif_repeat_all',
                RepeatMode.one => 'drawable/ic_notif_repeat_one',
              },
              label: 'Repeat',
              name: 'cycleRepeat',
            ),
          ]
        : const <MediaControl>[];

    playbackState.add(playbackState.value.copyWith(
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
    ));
  }
}
