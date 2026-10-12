import '../entities/playlist.dart';

/// Persistence contract for user-created playlists.
abstract interface class PlaylistRepository {
  List<Playlist> loadPlaylists();

  Future<void> savePlaylists(List<Playlist> playlists);
}
