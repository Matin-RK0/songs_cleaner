import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/settings/app_settings_repository.dart';
import '../../domain/entities/song.dart';
import '../../domain/services/library_query.dart';
import '../../domain/value_objects/song_sort.dart';
import '../../domain/value_objects/song_filter.dart';
import '../../infrastructure/artwork_cache_service.dart';
import '../../infrastructure/data_sources/device_music_data_source.dart';
import '../../infrastructure/media_permissions_service.dart';

final onAudioQueryProvider = Provider<OnAudioQuery>((ref) => OnAudioQuery());

final deviceMusicDataSourceProvider = Provider<DeviceMusicDataSource>(
  (ref) => DeviceMusicDataSource(ref.watch(onAudioQueryProvider)),
);

final mediaPermissionsProvider = Provider<MediaPermissionsService>(
  (ref) => MediaPermissionsService(),
);

final artworkCacheProvider = Provider<ArtworkCacheService>(
  (ref) => ArtworkCacheService(),
);

class LibraryState {
  const LibraryState({
    required this.songs,
    required this.visibleSongs,
    this.query = '',
    this.sort = SongSort.titleAsc,
    this.filter = SongFilter.all,
  });

  final List<Song> songs;
  final List<Song> visibleSongs;
  final String query;
  final SongSort sort;
  final SongFilter filter;

  LibraryState copyWith({
    List<Song>? songs,
    String? query,
    SongSort? sort,
    SongFilter? filter,
  }) {
    final nextSongs = songs ?? this.songs;
    final nextQuery = query ?? this.query;
    final nextSort = sort ?? this.sort;
    final nextFilter = filter ?? this.filter;
    return LibraryState(
      songs: nextSongs,
      visibleSongs: filterAndSortSongs(
        nextSongs,
        query: nextQuery,
        sort: nextSort,
        filter: nextFilter,
      ),
      query: nextQuery,
      sort: nextSort,
      filter: nextFilter,
    );
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryController, LibraryState>(
  LibraryController.new,
);

class LibraryController extends AsyncNotifier<LibraryState> {
  Future<void>? _deviceSync;
  int _libraryGeneration = 0;

  @override
  Future<LibraryState> build() async {
    ++_libraryGeneration;
    final permissions = ref.watch(mediaPermissionsProvider);
    if (!await permissions.requestAudioAccess()) {
      throw const PermissionFailure();
    }

    final source = ref.watch(deviceMusicDataSourceProvider);
    final fetched = await source.fetchSongs();
    final existing = await _keepExistingFiles(fetched);
    final restoredSort = _loadPersistedSort();

    return LibraryState(
      songs: List.unmodifiable(existing),
      visibleSongs: filterAndSortSongs(existing, query: '', sort: restoredSort),
      sort: restoredSort,
    );
  }

  /// The chosen ordering survives restarts; falls back to title ascending.
  SongSort _loadPersistedSort() {
    final settings = ref.watch(appSettingsRepositoryProvider);
    final fallbackIndex = SongSort.values.indexOf(SongSort.titleAsc);
    final index = settings
        .loadLibrarySortIndex(fallbackIndex)
        .clamp(0, SongSort.values.length - 1);
    return SongSort.values[index];
  }

  /// MediaStore rows can outlive their files (deleted outside the app or by
  /// us in an earlier session), so drop paths that no longer exist.
  static Future<List<Song>> _keepExistingFiles(List<Song> songs) async {
    const chunkSize = 64;
    final kept = <Song>[];
    for (var start = 0; start < songs.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, songs.length);
      final chunk = songs.sublist(start, end);
      final exists = await Future.wait(
        chunk.map((song) => File(song.path).exists()),
      );
      for (var i = 0; i < chunk.length; i++) {
        if (exists[i]) kept.add(chunk[i]);
      }
    }
    return kept;
  }

  void setQuery(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
  }

  void setSort(SongSort sort) {
    final current = state.value;
    if (current == null) return;
    ref.read(appSettingsRepositoryProvider).saveLibrarySortIndex(sort.index);
    state = AsyncData(current.copyWith(sort: sort));
  }

  void setFilter(SongFilter filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  /// Removes a song from the in-memory library after its file was deleted.
  void removeSongLocally(int songId) {
    final current = state.value;
    if (current == null) return;
    ++_libraryGeneration;
    final remaining = current.songs
        .where((song) => song.id != songId)
        .toList(growable: false);
    state = AsyncData(current.copyWith(songs: remaining));
  }

  /// Incrementally looks for songs added to the device since the last load and
  /// merges only the new ones. Avoids a full re-query and file-existence pass,
  /// so periodic checks stay cheap even on large libraries.
  Future<void> syncNewSongs() async {
    // A completed Telegram download must not be overwritten by an older full
    // snapshot that was requested while its publication was still in flight.
    final pending = _deviceSync;
    if (pending != null) await pending;
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    final generation = _libraryGeneration;

    final source = ref.read(deviceMusicDataSourceProvider);
    final candidates = await source.fetchSongsNewerThan(
      newestDateAddedSeconds(current.songs),
    );
    if (!ref.mounted ||
        generation != _libraryGeneration ||
        candidates.isEmpty) {
      return;
    }

    // Re-read the state: a manual refresh may have replaced the list while the
    // MediaStore query was in flight. mergeNewSongs de-duplicates by song id.
    final latest = state.value;
    if (latest == null) return;
    final merged = mergeNewSongs(latest.songs, candidates);
    if (identical(merged, latest.songs)) return;
    state = AsyncData(latest.copyWith(songs: merged));
  }

  /// Reconciles additions, deletions and metadata changes without replacing the
  /// visible page with a loading state or resetting its query/filter/order.
  Future<void> syncDeviceChanges() {
    final running = _deviceSync;
    if (running != null) return running;
    if (!state.hasValue) return Future.value();
    late final Future<void> pending;
    pending = _reconcileDeviceSongs(_libraryGeneration).whenComplete(() {
      if (identical(_deviceSync, pending)) _deviceSync = null;
    });
    _deviceSync = pending;
    return pending;
  }

  Future<void> _reconcileDeviceSongs(int generation) async {
    final source = ref.read(deviceMusicDataSourceProvider);
    final fetched = await source.fetchSongs();
    if (!ref.mounted || generation != _libraryGeneration) return;
    final existing = await _keepExistingFiles(fetched);
    if (!ref.mounted || generation != _libraryGeneration) return;
    final latest = state.value;
    if (latest == null) return;
    ++_libraryGeneration;
    state = AsyncData(latest.copyWith(songs: List.unmodifiable(existing)));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
