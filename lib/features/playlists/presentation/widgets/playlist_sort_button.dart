import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/playlist_order.dart';

class PlaylistSortButton<T> extends StatelessWidget {
  const PlaylistSortButton({
    super.key,
    required this.current,
    required this.options,
    required this.labelOf,
    required this.onSelected,
  });

  final T current;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: context.l10n.sortLabel,
    onSelected: onSelected,
    initialValue: current,
    itemBuilder: (_) => [
      for (final value in options)
        CheckedPopupMenuItem<T>(
          value: value,
          checked: current == value,
          child: Text(labelOf(value)),
        ),
    ],
    child: Padding(
      padding: AppSpacing.hSmVXs,
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                labelOf(current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String playlistListOrderLabel(AppLocalizations l10n, PlaylistListOrder order) =>
    switch (order) {
      PlaylistListOrder.name => l10n.playlistOrderName,
      PlaylistListOrder.updated => l10n.playlistOrderUpdated,
      PlaylistListOrder.trackCount => l10n.playlistOrderTrackCount,
      PlaylistListOrder.favorites => l10n.playlistOrderFavorites,
    };

String playlistTrackOrderLabel(
  AppLocalizations l10n,
  PlaylistTrackOrder order, {
  required bool custom,
}) => switch (order) {
  PlaylistTrackOrder.custom =>
    custom ? l10n.playlistOrderCustom : l10n.playlistOrderAutomatic,
  PlaylistTrackOrder.title => l10n.sortByTitle,
  PlaylistTrackOrder.artist => l10n.sortByArtist,
  PlaylistTrackOrder.album => l10n.sortByAlbum,
  PlaylistTrackOrder.dateAdded => l10n.sortByDateAdded,
};
