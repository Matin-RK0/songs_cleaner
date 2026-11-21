import '../../library/domain/entities/song.dart';
import '../../library/domain/value_objects/song_sort.dart';

enum PlaylistTrackOrder {
  custom(null),
  title(SongSort.titleAsc),
  artist(SongSort.artistAsc),
  album(SongSort.albumAsc),
  dateAdded(SongSort.dateAddedDesc);

  const PlaylistTrackOrder(this.sort);

  final SongSort? sort;

  static PlaylistTrackOrder restore(Object? value) =>
      values.firstWhere((order) => order.name == value, orElse: () => custom);

  List<Song> apply(List<Song> songs) {
    final order = sort;
    if (order == null) return songs;
    return List.unmodifiable(
      [...songs]..sort((a, b) {
        final result = order.compare(a, b);
        return result == 0 ? SongSort.titleAsc.compare(a, b) : result;
      }),
    );
  }
}
