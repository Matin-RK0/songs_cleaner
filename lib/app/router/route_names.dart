import '../../features/playlists/domain/entities/smart_playlist.dart';
import '../../features/library/domain/entities/song_collection.dart';

abstract final class RouteNames {
  static const String home = '/';
  static const String player = '/player';
  static const String search = '/search';
  static const String groupSongs = '/group-songs';
  static const String playlistDetail = '/playlist-detail';
  static const String settings = '/settings';
  static const String lockScreen = '/lock-screen';
  static const String history = '/history';
  static const String collectionSongs = '/collection-songs';
  static const String songDetails = '/song-details';
  static const String libraryInsights = '/library-insights';
  static const String duplicateScanner = '/duplicate-scanner';
  static const String equalizer = '/equalizer';
  static const String lyrics = '/lyrics';
  static const String tagEditor = '/tag-editor';
  static const String folderPicker = '/folder-picker';
  static const String trash = '/trash';
  static const String telegramAuth = '/telegram/auth';
  static const String telegramChat = '/telegram/chat';
  static const String telegramDownloads = '/telegram/downloads';
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

class CollectionSongsArgs {
  const CollectionSongsArgs({
    required this.kind,
    required this.key,
    required this.title,
  });

  final SongCollectionKind kind;
  final String key;
  final String title;
}
