import '../entities/song.dart';
import '../value_objects/song_sort.dart';

/// Pure filtering/sorting used by the library controller. Kept free of any
/// Flutter dependency so it can be unit tested directly.
List<Song> filterAndSortSongs(
  List<Song> songs, {
  required String query,
  required SongSort sort,
}) {
  final needle = query.trim().toLowerCase();
  final Iterable<Song> filtered;
  if (needle.isEmpty) {
    filtered = songs;
  } else {
    filtered = songs.where((song) {
      return song.title.toLowerCase().contains(needle) ||
          song.artist.toLowerCase().contains(needle) ||
          song.album.toLowerCase().contains(needle);
    });
  }
  final result = filtered.toList()..sort(sort.compare);
  return List.unmodifiable(result);
}

class MusicGroup {
  const MusicGroup({
    required this.id,
    required this.name,
    required this.songCount,
    required this.coverSongId,
    required this.totalDuration,
  });

  final int id;
  final String name;
  final int songCount;
  final int coverSongId;
  final Duration totalDuration;

  bool get isUnknown => name.isEmpty;
}

/// Groups songs by artist (or album) without mutating the input.
List<MusicGroup> groupSongs(
  List<Song> songs, {
  required int Function(Song) idOf,
  required String Function(Song) nameOf,
}) {
  final buckets = <int, List<Song>>{};
  for (final song in songs) {
    buckets.putIfAbsent(idOf(song), () => []).add(song);
  }
  final groups = buckets.entries.map((entry) {
    final bucketSongs = entry.value
      ..sort(SongSort.titleAsc.compare);
    return MusicGroup(
      id: entry.key,
      name: nameOf(bucketSongs.first),
      songCount: bucketSongs.length,
      coverSongId: bucketSongs.first.id,
      totalDuration: bucketSongs.fold<Duration>(
        Duration.zero,
        (sum, song) => sum + song.duration,
      ),
    );
  }).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List.unmodifiable(groups);
}
