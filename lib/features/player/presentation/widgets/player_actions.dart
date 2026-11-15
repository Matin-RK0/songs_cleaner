import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import 'queue_sheet.dart';
import 'player_icon.dart';

class PlayerActions extends ConsumerWidget {
  const PlayerActions({super.key, required this.song, this.locked = false});

  final Song song;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorite = ref.watch(
      libraryStatsProvider.select((stats) => stats.isFavorite(song.id)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!locked)
            IconButton(
              tooltip: l10n.queueTitle,
              color: context.colors.primary,
              iconSize: AppPlayerMetrics.icon,
              icon: const PlayerIcon(PlayerGlyph.queue),
              onPressed: () => showQueueSheet(context),
            )
          else
            const SizedBox(width: AppPlayerMetrics.transportExtent),
          IconButton(
            tooltip: favorite ? l10n.removeFromFavorites : l10n.addToFavorites,
            iconSize: AppPlayerMetrics.icon,
            color: favorite
                ? context.colors.primary
                : context.colors.primary.withValues(alpha: 0.65),
            icon: PlayerIcon(
              favorite ? PlayerGlyph.favorite : PlayerGlyph.favoriteOutline,
            ),
            onPressed: () =>
                ref.read(libraryStatsProvider.notifier).toggleFavorite(song.id),
          ),
          if (!locked)
            IconButton(
              tooltip: l10n.addToPlaylist,
              color: context.colors.primary,
              iconSize: AppPlayerMetrics.icon,
              icon: const PlayerIcon(PlayerGlyph.add),
              onPressed: () => showAddToPlaylistSheet(context, song),
            )
          else
            const SizedBox(width: AppPlayerMetrics.transportExtent),
        ],
      ),
    );
  }
}
