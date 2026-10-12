import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/services/library_query.dart';

void main() {
  Song song(int id, {int dateAddedSeconds = 0}) => Song(
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

  group('newestDateAddedSeconds', () {
    test('returns zero for an empty library', () {
      expect(newestDateAddedSeconds(const []), 0);
    });

    test('returns the greatest date-added value', () {
      expect(
        newestDateAddedSeconds([song(1, dateAddedSeconds: 10), song(2, dateAddedSeconds: 40)]),
        40,
      );
    });
  });

  group('mergeNewSongs', () {
    test('returns the same list when there is nothing to add', () {
      final existing = [song(1), song(2)];
      expect(identical(mergeNewSongs(existing, const []), existing), isTrue);
    });

    test('appends only songs whose id is not already present', () {
      final existing = [song(1), song(2)];
      final merged = mergeNewSongs(existing, [song(2), song(3)]);

      expect(merged.map((song) => song.id), [1, 2, 3]);
    });

    test('returns the same list instance when every candidate is known', () {
      final existing = [song(1), song(2)];
      expect(identical(mergeNewSongs(existing, [song(2)]), existing), isTrue);
    });

    test('does not mutate the input list', () {
      final existing = [song(1)];
      mergeNewSongs(existing, [song(2)]);

      expect(existing.map((song) => song.id), [1]);
    });
  });
}
