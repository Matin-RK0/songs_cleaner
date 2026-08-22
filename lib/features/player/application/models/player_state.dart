import '../../../library/domain/entities/song.dart';
import '../../domain/playback_enums.dart';

class PlayerState {
  const PlayerState({
    this.songs = const [],
    this.index = -1,
    this.playing = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.off,
    this.shuffled = false,
    this.processingState = PlayerProcessingState.idle,
    this.queueRevision = 0,
  });

  final List<Song> songs;
  final int index;
  final bool playing;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool shuffled;
  final PlayerProcessingState processingState;
  final int queueRevision;

  static const PlayerState initial = PlayerState();

  Song? get current =>
      (index >= 0 && index < songs.length) ? songs[index] : null;

  bool get hasCurrent => current != null;

  bool get isBuffering =>
      processingState == PlayerProcessingState.loading ||
      processingState == PlayerProcessingState.buffering;

  PlayerState copyWith({
    List<Song>? songs,
    int? index,
    bool? playing,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? shuffled,
    PlayerProcessingState? processingState,
    int? queueRevision,
  }) {
    return PlayerState(
      songs: songs ?? this.songs,
      index: index ?? this.index,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffled: shuffled ?? this.shuffled,
      processingState: processingState ?? this.processingState,
      queueRevision: queueRevision ?? this.queueRevision,
    );
  }
}
