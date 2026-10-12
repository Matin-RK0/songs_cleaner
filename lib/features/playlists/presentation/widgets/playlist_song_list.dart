import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';

/// Sliver song list for a playlist. Custom playlists pass [onReorder] to enable
/// drag handles; smart playlists omit it and stay read-only. Long-press exposes
/// the play/remove actions without stealing the drag gesture.
class PlaylistSongSliver extends StatelessWidget {
  const PlaylistSongSliver({
    super.key,
    required this.songs,
    required this.currentSongId,
    required this.onSongTap,
    this.onReorder,
    this.onRemove,
  });

  final List<Song> songs;
  final int? currentSongId;
  final void Function(List<Song> songs, int index) onSongTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final ValueChanged<Song>? onRemove;

  @override
  Widget build(BuildContext context) {
    final reorder = onReorder;
    if (reorder != null) {
      return SliverReorderableList(
        itemCount: songs.length,
        onReorderItem: reorder,
        proxyDecorator: _proxyDecorator,
        itemBuilder: (context, index) => _tile(
          context,
          index: index,
          song: songs[index],
          dragIndex: index,
        ),
      );
    }
    return SliverList.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) => _tile(
        context,
        index: index,
        song: songs[index],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required int index,
    required Song song,
    int? dragIndex,
  }) {
    return PlaylistSongTile(
      key: ValueKey(song.id),
      song: song,
      isCurrent: song.id == currentSongId,
      dragIndex: dragIndex,
      onTap: () => onSongTap(songs, index),
      onRemove: onRemove == null ? null : () => onRemove!(song),
    );
  }

  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return Material(color: Colors.transparent, elevation: 0, child: child);
  }
}

class PlaylistSongTile extends StatelessWidget {
  const PlaylistSongTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.onTap,
    this.dragIndex,
    this.onRemove,
  });

  final Song song;
  final bool isCurrent;
  final VoidCallback onTap;
  final int? dragIndex;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onRemove == null ? null : () => _showActions(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            minVerticalPadding: 0,
            leading: ArtworkImage(
              songId: song.id,
              size: 52,
              borderRadius: AppRadius.md,
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: isCurrent ? colors.primary : colors.textHigh,
              ),
            ),
            subtitle: Text(
              '${song.artist.isEmpty ? context.l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: colors.textMedium),
            ),
            trailing: dragIndex == null
                ? null
                : Semantics(
                    label: context.l10n.reorderTooltip,
                    child: ReorderableDragStartListener(
                      index: dragIndex!,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.sm,
                          end: AppSpacing.xs,
                        ),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: colors.textLow,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(l10n.playTooltipShort),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded),
              iconColor: colors.danger,
              textColor: colors.danger,
              title: Text(l10n.removeFromPlaylist),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onRemove?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
