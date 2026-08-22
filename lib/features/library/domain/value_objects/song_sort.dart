import '../entities/song.dart';

enum SongSort { titleAsc, artistAsc, dateAddedDesc, durationDesc }

extension SongSortX on SongSort {
  int compare(Song a, Song b) => switch (this) {
        SongSort.titleAsc => _compareText(a.title, b.title),
        SongSort.artistAsc => _compareText(a.artist, b.artist),
        SongSort.dateAddedDesc => b.dateAddedSeconds
            .compareTo(a.dateAddedSeconds),
        SongSort.durationDesc => b.duration.compareTo(a.duration),
      };

  static int _compareText(String a, String b) {
    final result = a.toLowerCase().compareTo(b.toLowerCase());
    return result != 0 ? result : a.compareTo(b);
  }
}
