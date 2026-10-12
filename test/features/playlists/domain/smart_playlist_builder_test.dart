import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/library_stats.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/smart_playlist.dart';
import 'package:songs_cleaner/features/playlists/domain/services/smart_playlist_builder.dart';

Song song(int id, {String title = 'Song', int added = 0}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  artistId: 1,
  duration: const Duration(minutes: 3),
  path: '/music/$id.mp3',
  sizeBytes: 1024,
  dateAddedSeconds: added,
);

List<int> ids(List<Song> songs) => songs.map((s) => s.id).toList();

void main() {
  group('SmartPlaylistBuilder.liked', () {
    test('keeps only favorites, preserving library order', () {
      final songs = [song(1), song(2), song(3), song(4)];
      const stats = LibraryStats(favoriteIds: {4, 2});

      final result = SmartPlaylistBuilder.build(
        kind: SmartPlaylistKind.liked,
        songs: songs,
        stats: stats,
      );

      expect(ids(result), [2, 4]);
    });
  });

  group('SmartPlaylistBuilder.recentlyAdded', () {
    test('sorts newest first by dateAddedSeconds', () {
      final songs = [
        song(1, added: 10),
        song(2, added: 30),
        song(3, added: 20),
      ];

      final result = SmartPlaylistBuilder.build(
        kind: SmartPlaylistKind.recentlyAdded,
        songs: songs,
        stats: LibraryStats.empty,
      );

      expect(ids(result), [2, 3, 1]);
    });
  });

  group('SmartPlaylistBuilder.mostPlayed', () {
    test('excludes unplayed songs and orders by count then title', () {
      final songs = [
        song(1, title: 'Bravo'),
        song(2, title: 'Alpha'),
        song(3, title: 'Zulu'),
        song(4, title: 'Never'),
      ];
      const stats = LibraryStats(playCounts: {1: 5, 2: 5, 3: 1});

      final result = SmartPlaylistBuilder.build(
        kind: SmartPlaylistKind.mostPlayed,
        songs: songs,
        stats: stats,
      );

      // 1 and 2 tie at 5 plays -> alphabetical; 3 has 1; 4 excluded.
      expect(ids(result), [2, 1, 3]);
    });
  });
}
