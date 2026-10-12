import '../../features/playlists/domain/entities/smart_playlist.dart';

abstract final class RouteNames {
  static const String home = '/';
  static const String player = '/player';
  static const String search = '/search';
  static const String groupSongs = '/group-songs';
  static const String playlistDetail = '/playlist-detail';
  static const String settings = '/settings';
  static const String lockScreen = '/lock-screen';
}

/// Navigation payload for the playlist detail screen. Exactly one of
/// [playlistId] (custom) or [smartKind] (derived) is set.
class PlaylistDetailArgs {
  const PlaylistDetailArgs.custom(String this.playlistId) : smartKind = null;

  const PlaylistDetailArgs.smart(SmartPlaylistKind this.smartKind)
    : playlistId = null;

  final String? playlistId;
  final SmartPlaylistKind? smartKind;
}

class GroupSongsArgs {
  const GroupSongsArgs({
    required this.isArtist,
    required this.id,
    required this.title,
  });

  final bool isArtist;
  final int id;
  final String title;
}
