import '../../../library/domain/entities/song.dart';
import '../../../library/domain/value_objects/library_stats.dart';
import '../entities/smart_playlist.dart';

/// Pure derivation of the smart playlists from the library and user signals.
/// Kept Flutter-free and side-effect-free so it is trivially unit-testable.
abstract final class SmartPlaylistBuilder {
  static List<Song> build({
    required SmartPlaylistKind kind,
    required List<Song> songs,
    required LibraryStats stats,
    Iterable<int> recentSongIds = const [],
  }) {
    switch (kind) {
      case SmartPlaylistKind.liked:
        return songs
            .where((song) => stats.isFavorite(song.id))
            .toList(growable: false);
      case SmartPlaylistKind.recentlyAdded:
        final sorted = [...songs]
          ..sort((a, b) => b.dateAddedSeconds.compareTo(a.dateAddedSeconds));
        return List.unmodifiable(sorted);
      case SmartPlaylistKind.mostPlayed:
        final played =
            songs
                .where((song) => stats.playCount(song.id) > 0)
                .toList(growable: false)
              ..sort((a, b) {
                final byCount = stats
                    .playCount(b.id)
                    .compareTo(stats.playCount(a.id));
                if (byCount != 0) return byCount;
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              });
        return played;
      case SmartPlaylistKind.recentlyPlayed:
        final byId = {for (final song in songs) song.id: song};
        final seen = <int>{};
        return List.unmodifiable([
          for (final id in recentSongIds)
            if (seen.add(id)) ?byId[id],
        ]);
    }
  }
}
