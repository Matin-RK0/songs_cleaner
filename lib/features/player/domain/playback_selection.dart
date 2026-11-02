import '../../library/domain/entities/song.dart';

/// Resolves a selected song inside its playback context, not a filtered view.
/// History may contain repeated entries or two IDs for the same local file.
class PlaybackSelection {
  PlaybackSelection(List<Song> context, {required Song selected}) {
    final ids = <int>{};
    final paths = <String>{};
    final unique = <Song>[];
    for (final song in context) {
      if (ids.contains(song.id) ||
          (song.path.isNotEmpty && paths.contains(song.path))) {
        continue;
      }
      ids.add(song.id);
      if (song.path.isNotEmpty) paths.add(song.path);
      unique.add(song);
    }
    var index = unique.indexWhere(
      (song) =>
          song.id == selected.id ||
          (selected.path.isNotEmpty && song.path == selected.path),
    );
    if (index < 0) {
      unique.insert(0, selected);
      index = 0;
    }
    songs = List.unmodifiable(unique);
    startIndex = index;
  }

  late final List<Song> songs;
  late final int startIndex;
}
