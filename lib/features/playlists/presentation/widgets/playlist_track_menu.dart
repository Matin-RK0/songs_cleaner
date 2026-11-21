import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/song_platform_actions.dart';
import '../../../player/application/providers/player_controller.dart';
import 'add_to_playlist_sheet.dart';

enum _TrackAction {
  play,
  playlist,
  next,
  queue,
  favorite,
  remove,
  share,
  details,
  album,
  artist,
  ringtone,
  delete,
}

class PlaylistTrackMenu extends ConsumerWidget {
  const PlaylistTrackMenu({
    super.key,
    required this.song,
    required this.onPlay,
    this.onRemove,
  });

  final Song song;
  final VoidCallback onPlay;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorite = ref.watch(
      libraryStatsProvider.select((state) => state.isFavorite(song.id)),
    );
    return PopupMenuButton<_TrackAction>(
      tooltip: l10n.moreActions,
      onSelected: (action) => _select(context, ref, action),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _TrackAction.play,
          child: Text(l10n.playTooltipShort),
        ),
        PopupMenuItem(
          value: _TrackAction.playlist,
          child: Text(l10n.addToPlaylist),
        ),
        PopupMenuItem(value: _TrackAction.next, child: Text(l10n.playNext)),
        PopupMenuItem(value: _TrackAction.queue, child: Text(l10n.addToQueue)),
        PopupMenuItem(
          value: _TrackAction.favorite,
          child: Text(
            favorite ? l10n.removeFromFavorites : l10n.addToFavorites,
          ),
        ),
        if (onRemove != null)
          PopupMenuItem(
            value: _TrackAction.remove,
            child: Text(l10n.removeFromPlaylist),
          ),
        if (Platform.isAndroid)
          PopupMenuItem(
            value: _TrackAction.share,
            child: Text(l10n.shareSongAction),
          ),
        PopupMenuItem(
          value: _TrackAction.details,
          child: Text(l10n.songDetailsTitle),
        ),
        if (song.albumId > 0 && song.album.isNotEmpty)
          PopupMenuItem(
            value: _TrackAction.album,
            child: Text(l10n.playlistGoToAlbum),
          ),
        if (song.artistId > 0 && song.artist.isNotEmpty)
          PopupMenuItem(
            value: _TrackAction.artist,
            child: Text(l10n.playlistGoToArtist),
          ),
        if (Platform.isAndroid && song.hasFile)
          PopupMenuItem(
            value: _TrackAction.ringtone,
            child: Text(l10n.setAsRingtoneAction),
          ),
        if (song.hasFile)
          PopupMenuItem(
            value: _TrackAction.delete,
            child: Text(
              l10n.deleteAction,
              style: TextStyle(color: context.colors.danger),
            ),
          ),
      ],
    );
  }

  void _select(BuildContext context, WidgetRef ref, _TrackAction action) {
    switch (action) {
      case _TrackAction.play:
        onPlay();
      case _TrackAction.playlist:
        showAddToPlaylistSheet(context, song);
      case _TrackAction.next:
        ref.read(playerProvider.notifier).playNext(song);
      case _TrackAction.queue:
        ref.read(playerProvider.notifier).addToQueue(song);
      case _TrackAction.favorite:
        ref.read(libraryStatsProvider.notifier).toggleFavorite(song.id);
      case _TrackAction.remove:
        onRemove?.call();
      case _TrackAction.share:
        shareSong(context, song);
      case _TrackAction.details:
        Navigator.of(context)
            .pushNamed(RouteNames.songDetails, arguments: song.id);
      case _TrackAction.album:
      case _TrackAction.artist:
        final artist = action == _TrackAction.artist;
        Navigator.of(context).pushNamed(
          RouteNames.groupSongs,
          arguments: GroupSongsArgs(
            isArtist: artist,
            id: artist ? song.artistId : song.albumId,
            title: artist ? song.artist : song.album,
          ),
        );
      case _TrackAction.ringtone:
        setSongAsRingtone(context, song);
      case _TrackAction.delete:
        deleteSongFlow(context, ref, song);
    }
  }
}
