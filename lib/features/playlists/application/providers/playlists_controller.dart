import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/playlist_order.dart';
import '../../infrastructure/playlist_cover_store.dart';
import '../../../library/domain/entities/song.dart';
import '../playlist_transfer_service.dart';
import 'playlist_providers.dart';

/// Ordered list of user-created playlists. Local storage is synchronous, so
/// the state is available immediately (no loading/error phase).
final playlistsProvider = NotifierProvider<PlaylistsController, List<Playlist>>(
  PlaylistsController.new,
);

class PlaylistsController extends Notifier<List<Playlist>> {
  Future<void> _pendingSave = Future<void>.value();

  @override
  List<Playlist> build() {
    final repository = ref.watch(playlistRepositoryProvider);
    return List.unmodifiable(repository.loadPlaylists());
  }

  Playlist? playlistById(String id) {
    for (final playlist in state) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  Future<Playlist> create(String name) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      songIds: const <int>[],
      createdAt: now,
      updatedAt: now,
    );
    _commit([...state, playlist]);
    return playlist;
  }

  Future<void> rename(String id, String name) async {
    _update(
      id,
      (playlist) =>
          playlist.copyWith(name: name.trim(), updatedAt: DateTime.now()),
    );
  }

  Future<void> remove(String id) async {
    final cover = playlistById(id)?.coverPath;
    final store = ref.read(playlistCoverStoreProvider);
    _commit(state.where((playlist) => playlist.id != id).toList());
    if (cover == null) return;
    await _pendingSave;
    await store.remove(cover);
  }

  void toggleFavorite(String id) => _update(
    id,
    (playlist) => playlist.copyWith(isFavorite: !playlist.isFavorite),
  );

  void setTrackOrder(String id, PlaylistTrackOrder order) =>
      _update(id, (playlist) => playlist.copyWith(trackOrder: order));

  Future<void> pickCover(String id) async {
    final store = ref.read(playlistCoverStoreProvider);
    final path = await store.pick();
    if (path == null) return;
    if (!ref.mounted || playlistById(id) == null) {
      await store.remove(path);
      return;
    }
    await _setCover(id, path);
  }

  Future<void> resetCover(String id) => _setCover(id, null);

  Future<void> _setCover(String id, String? path) async {
    final previous = playlistById(id)?.coverPath;
    final store = ref.read(playlistCoverStoreProvider);
    _update(
      id,
      (playlist) =>
          playlist.copyWith(coverPath: path, resetCover: path == null),
    );
    await _pendingSave;
    if (previous != path) await store.remove(previous);
  }

  Future<int> importPlaylists(
    List<ImportedPlaylist> imported,
    List<Song> songs,
    String fallbackName,
  ) async {
    final songsByPath = {for (final song in songs) song.path: song.id};
    var added = 0;
    final next = [...state];
    for (final item in imported) {
      final ids = item.songPaths
          .map((path) => songsByPath[path])
          .whereType<int>()
          .toSet()
          .toList();
      final now = DateTime.now();
      next.add(
        Playlist(
          id: '${now.microsecondsSinceEpoch}_${added++}',
          name: item.name.trim().isEmpty ? fallbackName : item.name.trim(),
          songIds: List.unmodifiable(ids),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (added > 0) _commit(next);
    return added;
  }

  Future<void> addSong(String id, int songId) async {
    _update(id, (playlist) {
      if (playlist.contains(songId)) return playlist;
      return playlist.copyWith(
        songIds: List.unmodifiable([...playlist.songIds, songId]),
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> addSongs(String id, Iterable<int> songIds) async {
    _update(id, (playlist) {
      final merged = <int>{...playlist.songIds, ...songIds}.toList();
      if (merged.length == playlist.songIds.length) return playlist;
      return playlist.copyWith(
        songIds: List.unmodifiable(merged),
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> removeSongs(String id, Iterable<int> songIds) async {
    final removed = songIds.toSet();
    _update(id, (playlist) {
      final remaining = playlist.songIds
          .where((songId) => !removed.contains(songId))
          .toList(growable: false);
      if (remaining.length == playlist.songIds.length) return playlist;
      return playlist.copyWith(
        songIds: List.unmodifiable(remaining),
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> removeSong(String id, int songId) async {
    _update(id, (playlist) {
      if (!playlist.contains(songId)) return playlist;
      return playlist.copyWith(
        songIds: List.unmodifiable(
          playlist.songIds.where((existing) => existing != songId).toList(),
        ),
        updatedAt: DateTime.now(),
      );
    });
  }

  /// Moves a song within a custom playlist (drag and drop). [newIndex] follows
  /// [SliverReorderableList.onReorderItem] semantics: already adjusted for the
  /// removed item, so it is the final target index.
  Future<void> reorder(String id, int oldIndex, int newIndex) async {
    _update(id, (playlist) {
      final ids = [...playlist.songIds];
      if (oldIndex < 0 || oldIndex >= ids.length) return playlist;
      final target = newIndex.clamp(0, ids.length - 1);
      final moved = ids.removeAt(oldIndex);
      ids.insert(target, moved);
      return playlist.copyWith(
        songIds: List.unmodifiable(ids),
        updatedAt: DateTime.now(),
      );
    });
  }

  /// Visible indices omit files that are no longer in the library. Move by
  /// identity so dragging cannot accidentally move one of those missing IDs.
  Future<void> reorderVisible(
    String id,
    List<Song> visible,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= visible.length ||
        newIndex >= visible.length) {
      return;
    }
    final playlist = playlistById(id);
    if (playlist == null) return;
    final from = playlist.songIds.indexOf(visible[oldIndex].id);
    final to = playlist.songIds.indexOf(visible[newIndex].id);
    if (from >= 0 && to >= 0) await reorder(id, from, to);
  }

  void _update(String id, Playlist Function(Playlist) transform) {
    final next = <Playlist>[
      for (final playlist in state)
        playlist.id == id ? transform(playlist) : playlist,
    ];
    _commit(next);
  }

  void _commit(List<Playlist> playlists) {
    final snapshot = List<Playlist>.unmodifiable(playlists);
    state = snapshot;
    final repository = ref.read(playlistRepositoryProvider);
    _pendingSave = _pendingSave
        .catchError((Object _) {})
        .then((_) => repository.savePlaylists(snapshot));
  }
}
