import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/library_stats.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/playlist.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/smart_playlist.dart';
import 'package:songs_cleaner/features/playlists/domain/playlist_order.dart';
import 'package:songs_cleaner/features/playlists/domain/services/playlist_picker_catalog.dart';
import 'package:songs_cleaner/features/playlists/domain/services/smart_playlist_builder.dart';

void main() {
  final library = [
    _song(1, 'Zephyr', 10, 'Mix', '/first/Live'),
    _song(2, 'Ash', 10, 'Mix', '/second/Live'),
    _song(3, 'Brooks', 11, 'Studio', '/second/Live'),
    _song(4, 'Clouds', 10, 'Mix', '/second/Live'),
  ];

  test('album groups skip existing tracks and return only selectable IDs', () {
    final albums = buildPlaylistPickerCatalog(library, [
      2,
    ], PlaylistPickerTab.albums);
    expect(albums.map((entry) => entry.title), ['Mix', 'Studio']);
    expect(albums.first.ids, [4, 1]);
    expect(
      filterPlaylistPickerCatalog(
        albums,
        PlaylistPickerTab.albums,
        ' studio ',
      ).single.ids,
      [3],
    );
  });

  test('folders with the same display name remain separate', () {
    final folders = buildPlaylistPickerCatalog(
      library,
      [],
      PlaylistPickerTab.folders,
    );
    expect(folders.map((entry) => entry.title), ['Live', 'Live']);
    expect(
      filterPlaylistPickerCatalog(
        folders,
        PlaylistPickerTab.folders,
        '/first',
      ).single.ids,
      [1],
    );
  });

  test('recent playback is deduplicated, keeping chronology and skipping missing files', () {
    final recent = SmartPlaylistBuilder.build(
      kind: SmartPlaylistKind.recentlyPlayed,
      songs: library,
      stats: LibraryStats.empty,
      recentSongIds: [3, 1, 3, 99, 2],
    );
    expect(recent.map((song) => song.id), [3, 1, 2]);
  });

  test(
    'sorting a track view does not mutate custom order or playlist metadata',
    () {
      final now = DateTime(2026);
      final original = Playlist(
        id: 'mix',
        name: 'Mix',
        songIds: [1, 2],
        createdAt: now,
        updatedAt: now,
      );
      final upgraded = original.copyWith(
        isFavorite: true,
        trackOrder: PlaylistTrackOrder.title,
        coverPath: '/covers/mix.jpg',
      );
      final restored = Playlist.fromJson(upgraded.toJson())!;
      expect(restored.isFavorite, isTrue);
      expect(restored.trackOrder, PlaylistTrackOrder.title);
      expect(restored.coverPath, '/covers/mix.jpg');
      expect(restored.copyWith(resetCover: true).coverPath, isNull);
      expect(
        Playlist.fromJson(original.toJson())!.trackOrder,
        PlaylistTrackOrder.custom,
      );
      expect(PlaylistTrackOrder.title.apply(library).map((song) => song.id), [
        2,
        3,
        4,
        1,
      ]);
      expect(library.map((song) => song.id), [1, 2, 3, 4]);
    },
  );
}

Song _song(int id, String title, int albumId, String album, String folder) =>
    Song(
      id: id,
      title: title,
      artist: 'Artist',
      album: album,
      albumId: albumId,
      artistId: 1,
      duration: const Duration(minutes: 2),
      path: '$folder/$id.mp3',
      folderPath: folder,
      sizeBytes: 1,
      dateAddedSeconds: id,
    );
