import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../domain/services/library_query.dart';
import 'library_controller.dart';

/// Small thumbnails for list tiles; autoDispose keeps memory bounded while
/// the LRU inside ArtworkCacheService smooths fast scrolling.
final songArtworkProvider =
    FutureProvider.autoDispose.family<Uint8List?, (int, int)>((ref, key) async {
  final songId = key.$1;
  final size = key.$2;
  final cache = ref.watch(artworkCacheProvider);
  return cache.artworkFor(songId, size: size);
});

final visibleSongsProvider = Provider<List<Song>>(
  (ref) => ref.watch(libraryProvider).value?.visibleSongs ?? const [],
);

final allSongsProvider = Provider<List<Song>>(
  (ref) => ref.watch(libraryProvider).value?.songs ?? const [],
);

final artistGroupsProvider = Provider<List<MusicGroup>>(
  (ref) => groupSongs(
    ref.watch(allSongsProvider),
    idOf: (song) => song.artistId,
    nameOf: (song) => song.artist,
  ),
);

final albumGroupsProvider = Provider<List<MusicGroup>>(
  (ref) => groupSongs(
    ref.watch(allSongsProvider),
    idOf: (song) => song.albumId,
    nameOf: (song) => song.album,
  ),
);

final songsByArtistProvider = Provider.family<List<Song>, int>(
  (ref, artistId) => ref
      .watch(allSongsProvider)
      .where((song) => song.artistId == artistId)
      .toList(growable: false),
);

final songsByAlbumProvider = Provider.family<List<Song>, int>(
  (ref, albumId) => ref
      .watch(allSongsProvider)
      .where((song) => song.albumId == albumId)
      .toList(growable: false),
);
