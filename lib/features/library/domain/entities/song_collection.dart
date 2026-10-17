import 'song.dart';

enum SongCollectionKind { genre, folder }

class SongCollection {
  const SongCollection({
    required this.key,
    required this.name,
    required this.songs,
    required this.totalDuration,
  });

  final String key;
  final String name;
  final List<Song> songs;
  final Duration totalDuration;

  int get songCount => songs.length;

  int get coverSongId => songs.first.id;
}
