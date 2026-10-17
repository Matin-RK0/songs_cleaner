import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../app/router/route_names.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../application/providers/library_stats_controller.dart';
import '../../domain/entities/song.dart';
import '../widgets/song_tile.dart';

class SongListView extends ConsumerWidget {
  const SongListView({
    super.key,
    required this.songs,
    required this.currentSongId,
    this.onSongTap,
    this.physics = const ClampingScrollPhysics(),
    this.controller,
    this.itemExtent,
    this.selectedSongIds = const <int>{},
    this.onSelectionChanged,
  });

  final List<Song> songs;
  final int? currentSongId;
  final void Function(List<Song> songs, int index)? onSongTap;
  final ScrollPhysics physics;
  final ScrollController? controller;
  final double? itemExtent;
  final Set<int> selectedSongIds;
  final ValueChanged<int>? onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: controller,
      itemExtent: itemExtent,
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpacing.xl,
        start: AppSpacing.xs,
        end: AppSpacing.sm,
      ),
      physics: physics,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isFavorite = ref.watch(
          libraryStatsProvider.select((stats) => stats.isFavorite(song.id)),
        );
        return SongTile(
          key: ValueKey(song.id),
          song: song,
          isCurrent: song.id == currentSongId,
          isFavorite: isFavorite,
          selected: selectedSongIds.contains(song.id),
          onTap: onSelectionChanged != null && selectedSongIds.isNotEmpty
              ? () => onSelectionChanged!(song.id)
              : () => onSongTap?.call(songs, index),
          onSelectionLongPress: onSelectionChanged == null
              ? null
              : () => onSelectionChanged!(song.id),
          onAddToPlaylist: (target) => showAddToPlaylistSheet(context, target),
          onToggleFavorite: () =>
              ref.read(libraryStatsProvider.notifier).toggleFavorite(song.id),
          onDeleteDevice: (target) => deleteSongFlow(context, ref, target),
          onShowInfo: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.songDetails, arguments: song.id),
        );
      },
    );
  }
}
