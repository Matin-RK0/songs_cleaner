import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/playlist.dart';
import 'playlist_artwork.dart';

class PlaylistDetailHeader extends StatelessWidget {
  const PlaylistDetailHeader({
    super.key,
    required this.title,
    required this.duration,
    required this.songCount,
    required this.artworkIds,
    required this.playlist,
    required this.emptyIcon,
  });

  final String title;
  final Duration duration;
  final int songCount;
  final List<int> artworkIds;
  final Playlist? playlist;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: AppSpacing.allLg,
      margin: AppSpacing.hMdVSm,
      decoration: BoxDecoration(
        borderRadius: AppRadius.xl,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.surfaceHigh, colors.surface],
        ),
      ),
      child: Column(
        children: [
          PlaylistArtwork(
            songIds: artworkIds,
            size: AppSpacing.avatarLarge * 2 + AppSpacing.xl,
            borderRadius: AppRadius.xl,
            heroTag: playlist == null ? null : 'playlist-art-${playlist!.id}',
            coverPath: playlist?.coverPath,
            placeholderIcon: emptyIcon,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.playerTitle.copyWith(color: colors.textHigh),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.playlistMetaLabel(songCount, duration.mmss),
            textAlign: TextAlign.center,
            style: AppTypography.meta.copyWith(color: colors.textMedium),
          ),
        ],
      ),
    );
  }
}

class PlaylistTrackControls extends StatelessWidget {
  const PlaylistTrackControls({
    super.key,
    required this.sort,
    required this.onPlay,
    required this.onShuffle,
  });

  final Widget sort;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) => Container(
    margin: AppSpacing.hMdVSm,
    padding: AppSpacing.hSmVXs,
    decoration: BoxDecoration(
      color: context.colors.surfaceHigh,
      borderRadius: AppRadius.lg,
    ),
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: sort,
          ),
        ),
        IconButton(
          tooltip: context.l10n.shuffleTooltip,
          onPressed: onShuffle,
          icon: const Icon(Icons.shuffle_rounded),
        ),
        IconButton.filled(
          tooltip: context.l10n.playTooltip,
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow_rounded),
        ),
      ],
    ),
  );
}

class PlaylistEditToolbar extends StatelessWidget {
  const PlaylistEditToolbar({
    super.key,
    required this.count,
    required this.onDone,
    this.onSelectAll,
    this.onPlay,
    this.onRemove,
  });

  final int count;
  final VoidCallback onDone;
  final VoidCallback? onSelectAll;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.colors.surfaceHigh,
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.playlistFinishEditing,
            onPressed: onDone,
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              count == 0 ? l10n.playlistEditTracks : l10n.selectedCount(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: l10n.selectAll,
            onPressed: onSelectAll,
            icon: const Icon(Icons.select_all_rounded),
          ),
          IconButton(
            tooltip: l10n.playTooltip,
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(
            tooltip: l10n.removeFromPlaylist,
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
