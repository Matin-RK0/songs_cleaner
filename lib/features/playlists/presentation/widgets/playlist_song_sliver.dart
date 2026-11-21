import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import 'playlist_track_menu.dart';

class PlaylistSongSliver extends StatelessWidget {
  const PlaylistSongSliver({
    super.key,
    required this.songs,
    required this.currentSongId,
    required this.onSongTap,
    this.onReorder,
    this.onRemove,
    this.selectedSongIds = const {},
    this.onSelectionChanged,
    this.selectionMode = false,
    this.showTrackMenu = false,
  });

  static const itemExtent = AppSpacing.trackRowHeight;
  final List<Song> songs;
  final int? currentSongId;
  final void Function(List<Song>, int) onSongTap;
  final void Function(int, int)? onReorder;
  final ValueChanged<Song>? onRemove;
  final Set<int> selectedSongIds;
  final ValueChanged<int>? onSelectionChanged;
  final bool selectionMode;
  final bool showTrackMenu;

  @override
  Widget build(BuildContext context) {
    final reorder = onReorder;
    if (reorder != null) {
      return SliverReorderableList(
        itemCount: songs.length,
        itemExtent: itemExtent,
        onReorderItem: reorder,
        proxyDecorator: (child, _, _) =>
            Material(color: context.colors.surfaceHigh, child: child),
        itemBuilder: (_, index) => _tile(index, dragIndex: index),
      );
    }
    return SliverFixedExtentList.builder(
      itemCount: songs.length,
      itemExtent: itemExtent,
      itemBuilder: (_, index) => _tile(index),
    );
  }

  Widget _tile(int index, {int? dragIndex}) {
    final song = songs[index];
    final changeSelection = onSelectionChanged;
    void play() => onSongTap(songs, index);
    return _PlaylistTrackRow(
      key: ValueKey(song.id),
      song: song,
      isCurrent: song.id == currentSongId,
      selectionMode: selectionMode,
      selected: selectedSongIds.contains(song.id),
      onTap: selectionMode && changeSelection != null
          ? () => changeSelection(song.id)
          : play,
      onLongPress: changeSelection == null
          ? null
          : () => changeSelection(song.id),
      trailing: !selectionMode && showTrackMenu
          ? PlaylistTrackMenu(
              song: song,
              onPlay: play,
              onRemove: onRemove == null ? null : () => onRemove!(song),
            )
          : null,
      dragIndex: dragIndex,
    );
  }
}

class _PlaylistTrackRow extends StatelessWidget {
  const _PlaylistTrackRow({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.dragIndex,
    this.trailing,
  });

  final Song song;
  final bool isCurrent;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? dragIndex;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final drag = dragIndex;
    return Material(
      borderRadius: AppRadius.md,
      color: selected ? colors.surfaceHigh : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        selected: selected,
        contentPadding: AppSpacing.hSmVXs,
        leading: ArtworkImage(
          songId: song.id,
          size: AppSpacing.avatarSize,
          borderRadius: AppRadius.md,
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.songTitle.copyWith(
            color: isCurrent ? colors.primary : colors.textHigh,
          ),
        ),
        subtitle: Text(
          '${song.artist.isEmpty ? l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.songSubtitle.copyWith(color: colors.textMedium),
        ),
        trailing: drag != null
            ? Semantics(
                label: l10n.reorderTooltip,
                child: ReorderableDragStartListener(
                  index: drag,
                  child: SizedBox.square(
                    dimension: kMinInteractiveDimension,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: colors.textLow,
                    ),
                  ),
                ),
              )
            : selectionMode
            ? Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.textLow,
              )
            : trailing,
      ),
    );
  }
}
