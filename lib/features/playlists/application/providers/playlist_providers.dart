import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/smart_playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/services/smart_playlist_builder.dart';
import '../../infrastructure/repositories/playlist_repository_impl.dart';
import 'playlists_controller.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

/// Resolves a custom playlist's stored song ids to live library songs,
/// preserving playlist order and silently skipping ids no longer present.
final playlistSongsProvider = Provider.family<List<Song>, String>((
  ref,
  playlistId,
) {
  final playlists = ref.watch(playlistsProvider);
  Playlist? playlist;
  for (final candidate in playlists) {
    if (candidate.id == playlistId) {
      playlist = candidate;
      break;
    }
  }
  if (playlist == null) return const <Song>[];

  final byId = ref.watch(songsByIdProvider);
  return <Song>[
    for (final songId in playlist.songIds) ?byId[songId],
  ];
});

/// Songs behind each smart playlist, derived from the library and user signals.
final smartPlaylistSongsProvider = Provider.family<List<Song>, SmartPlaylistKind>(
  (ref, kind) => SmartPlaylistBuilder.build(
    kind: kind,
    songs: ref.watch(allSongsProvider),
    stats: ref.watch(libraryStatsProvider),
  ),
);
