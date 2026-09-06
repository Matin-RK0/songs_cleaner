import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_sort.dart';

void main() {
  Song song(int id, int dateAddedSeconds) => Song(
        id: id,
        title: 'Song $id',
        artist: '',
        album: '',
        albumId: 0,
        artistId: 0,
        duration: Duration.zero,
        path: '/music/$id.mp3',
        sizeBytes: 0,
        dateAddedSeconds: dateAddedSeconds,
      );

  test('date-added sort puts the newest song first', () {
    final songs = [song(1, 10), song(2, 30), song(3, 20)]
      ..sort(SongSort.dateAddedDesc.compare);

    expect(songs.map((song) => song.id), [2, 3, 1]);
  });
}
