import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/services/library_query.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_filter.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_sort.dart';

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
        newestDateAddedSeconds([
          song(1, dateAddedSeconds: 10),
          song(2, dateAddedSeconds: 40),
        ]),
        40,
      );
    });
  });

  group('filterAndSortSongs', () {
    test('filters missing metadata and searches genre and folder', () {
      final songs = [
        song(1),
        Song(
          id: 2,
          title: 'Track',
          artist: 'Artist',
          album: 'Album',
          albumId: 1,
          artistId: 1,
          duration: const Duration(minutes: 3),
          path: '/music/rock/track.flac',
          sizeBytes: 1,
          dateAddedSeconds: 0,
          genre: 'Rock',
          folderPath: '/music/rock',
          fileExtension: 'flac',
        ),
      ];

      expect(
        filterAndSortSongs(
          songs,
          query: '',
          sort: SongSort.titleAsc,
          filter: SongFilter.missingMetadata,
        ).map((item) => item.id),
        [1],
      );
      expect(
        filterAndSortSongs(
          songs,
          query: 'rock',
          sort: SongSort.titleAsc,
        ).map((item) => item.id),
        [2],
      );
    });

    test('recognizes common lossless extensions', () {
      final flac = Song(
        id: 7,
        title: 'Lossless',
        artist: 'Artist',
        album: 'Album',
        albumId: 1,
        artistId: 1,
        duration: const Duration(minutes: 3),
        path: '/music/lossless.flac',
        sizeBytes: 1,
        dateAddedSeconds: 0,
        fileExtension: 'flac',
      );

      expect(SongFilter.lossless.matches(flac), isTrue);
      expect(SongFilter.shortTracks.matches(flac), isFalse);
    });
  });

  test('groups string collections and sorts their songs', () {
    final songs = [song(2), song(1), song(3)];
    final groups = groupSongCollections(
      songs,
      keyOf: (item) => item.id == 3 ? 'b' : 'a',
      nameOf: (item) => item.id == 3 ? 'B' : 'A',
    );

    expect(groups.map((group) => group.key), ['a', 'b']);
    expect(groups.first.songs.map((item) => item.id), [1, 2]);
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
