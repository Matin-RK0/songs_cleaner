import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../../../core/utils/alphabet_index.dart';
import '../../../history/application/providers/play_history_controller.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/smart_playlist.dart';
import '../../domain/playlist_order.dart';
import '../../../library/domain/value_objects/song_sort.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/services/smart_playlist_builder.dart';
import '../../infrastructure/repositories/playlist_repository_impl.dart';
import 'playlists_controller.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

/// Resolves a custom playlist's stored song ids to live library songs,
/// preserving playlist order and silently skipping ids no longer present.
final playlistSongsProvider = Provider.autoDispose.family<List<Song>, String>((
  ref,
  playlistId,
) {
  final songIds = ref.watch(
    playlistsProvider.select((playlists) {
      for (final playlist in playlists) {
        if (playlist.id == playlistId) return playlist.songIds;
      }
      return const <int>[];
    }),
  );
  if (songIds.isEmpty) return const <Song>[];

  final byId = ref.watch(songsByIdProvider);
  return <Song>[for (final songId in songIds) ?byId[songId]];
});

final orderedPlaylistsProvider =
    Provider.family<List<Playlist>, PlaylistListOrder>(
      (ref, order) => order.apply(ref.watch(playlistsProvider)),
    );

final playlistListOrderProvider =
    NotifierProvider<PlaylistListOrderController, PlaylistListOrder>(
      PlaylistListOrderController.new,
    );

class PlaylistListOrderController extends Notifier<PlaylistListOrder> {
  @override
  PlaylistListOrder build() => PlaylistListOrder.restore(
    ref
        .watch(appSettingsRepositoryProvider)
        .loadPlaylistListOrder(PlaylistListOrder.name.name),
  );

  Future<void> setOrder(PlaylistListOrder order) async {
    if (state == order) return;
    state = order;
    await ref
        .read(appSettingsRepositoryProvider)
        .savePlaylistListOrder(order.name);
  }
}

typedef PlaylistBrowseView = ({List<Playlist> rows, bool hasPlaylists});

final playlistBrowseProvider = Provider.autoDispose
    .family<PlaylistBrowseView, (PlaylistListOrder, String)>((ref, input) {
      final (order, query) = input;
      final all = ref.watch(orderedPlaylistsProvider(order));
      final rows = query.isEmpty
          ? all
          : all
                .where(
                  (playlist) => playlist.name.toLowerCase().contains(query),
                )
                .toList(growable: false);
      return (rows: rows, hasPlaylists: all.isNotEmpty);
    });

typedef PlaylistTrackView = ({
  List<Song> songs,
  List<int> artworkIds,
  Map<String, int> alphabet,
  Duration duration,
});

final playlistTrackViewProvider = Provider.autoDispose
    .family<
      PlaylistTrackView,
      (String?, SmartPlaylistKind?, PlaylistTrackOrder)
    >((ref, input) {
      final (id, kind, order) = input;
      final original = id == null
          ? ref.watch(smartPlaylistSongsProvider(kind!))
          : ref.watch(playlistSongsProvider(id));
      final songs = order.apply(original);
      final label = order.sort?.alphabeticalField;
      return (
        songs: songs,
        artworkIds: original
            .take(4)
            .map((song) => song.id)
            .toList(growable: false),
        alphabet: label == null
            ? const {}
            : buildAlphabetIndex(songs.map(label)),
        duration: songs.fold(
          Duration.zero,
          (total, song) => total + song.duration,
        ),
      );
    });

/// Songs behind each smart playlist, derived from the library and user signals.
final smartPlaylistSongsProvider =
    Provider.family<List<Song>, SmartPlaylistKind>(
      (ref, kind) => SmartPlaylistBuilder.build(
        kind: kind,
        songs: ref.watch(allSongsProvider),
        stats: ref.watch(libraryStatsProvider),
        recentSongIds: kind == SmartPlaylistKind.recentlyPlayed
            ? ref.watch(playHistoryProvider).map((entry) => entry.songId)
            : const [],
      ),
    );
