import '../../../core/settings/app_settings_repository.dart';
import '../../library/domain/entities/song.dart';
import '../domain/playback_enums.dart';

/// The plan for resuming a previously persisted playback session, derived from
/// a [SavedPlaybackSession] and the current device library (fresh MediaStore
/// rows mapped by song id).
class RestoredSession {
  const RestoredSession({
    required this.queue,
    required this.current,
    required this.position,
    required this.repeatMode,
    required this.shuffled,
  });

  final List<Song> queue;
  final Song current;
  final Duration position;
  final RepeatMode repeatMode;
  final bool shuffled;
}

/// Pure, testable translation of a persisted session into concrete library
/// songs. Kept outside the controller so resume logic can be unit-tested
/// without Flutter/Riverpod.
class SessionResumePlanner {
  const SessionResumePlanner._();

  /// Returns the resume plan, or null when there is nothing restorable (no
  /// session, or the current track is no longer present in the library).
  static RestoredSession? plan(
    SavedPlaybackSession? session,
    List<Song> librarySongs,
  ) {
    if (session == null || !session.isRestorable) return null;

    final byId = {for (final song in librarySongs) song.id: song};
    final queue = [
      for (final id in session.queueSongIds)
        if (byId[id] != null) byId[id]!,
    ];
    final current = byId[session.currentSongId];
    if (current == null || queue.isEmpty) return null;

    final repeatIndex = session.repeatModeIndex.clamp(
      0,
      RepeatMode.values.length - 1,
    );
    return RestoredSession(
      queue: queue,
      current: current,
      position: Duration(milliseconds: session.positionMs),
      repeatMode: RepeatMode.values[repeatIndex],
      shuffled: session.shuffled,
    );
  }
}
