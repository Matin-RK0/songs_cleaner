import '../../../library/domain/entities/song.dart';

class DuplicateGroup {
  const DuplicateGroup({
    required this.id,
    required this.songs,
    required this.recommendedSong,
  });

  final String id;
  final List<Song> songs;
  final Song recommendedSong;

  int get recoverableBytes => songs
      .where((song) => song.id != recommendedSong.id)
      .fold(0, (total, song) => total + song.sizeBytes);
}
