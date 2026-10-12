import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Stores all playlists as a single JSON array. Reads are synchronous so the
/// controller can expose playlists without a loading state; writes are compact
/// and atomic from the caller's perspective.
class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _playlistsKey = 'playlists.items.v1';

  @override
  List<Playlist> loadPlaylists() {
    final raw = _prefs.getString(_playlistsKey);
    if (raw == null) return const <Playlist>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Playlist>[];
      return decoded
          .map(Playlist.fromJson)
          .whereType<Playlist>()
          .toList(growable: false);
    } on FormatException {
      return const <Playlist>[];
    }
  }

  @override
  Future<void> savePlaylists(List<Playlist> playlists) async {
    await _prefs.setString(
      _playlistsKey,
      jsonEncode(
        playlists.map((playlist) => playlist.toJson()).toList(growable: false),
      ),
    );
  }
}
