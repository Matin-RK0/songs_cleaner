import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playlist.dart';
import 'playlist_providers.dart';

/// Ordered list of user-created playlists. Local storage is synchronous, so
/// the state is available immediately (no loading/error phase).
final playlistsProvider = NotifierProvider<PlaylistsController, List<Playlist>>(
  PlaylistsController.new,
);

class PlaylistsController extends Notifier<List<Playlist>> {
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
    _commit(state.where((playlist) => playlist.id != id).toList());
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

  void _update(String id, Playlist Function(Playlist) transform) {
    final next = <Playlist>[
      for (final playlist in state)
        playlist.id == id ? transform(playlist) : playlist,
    ];
    _commit(next);
  }

  void _commit(List<Playlist> playlists) {
    state = List.unmodifiable(playlists);
    unawaited(ref.read(playlistRepositoryProvider).savePlaylists(state));
  }
}
