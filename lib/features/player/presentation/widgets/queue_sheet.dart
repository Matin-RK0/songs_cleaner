import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';
import 'artwork_ambient_background.dart';
import 'player_controls_row.dart';
import 'seek_bar.dart';

/// Bottom sheet listing the active play queue.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.95,
    ),
    builder: (_) => const _QueuePlayerSheet(),
  );
}

class _QueuePlayerSheet extends ConsumerWidget {
  const _QueuePlayerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    return ArtworkAmbientBackground(
      songId: song?.id,
      visible: song != null,
      subdued: true,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const Expanded(child: QueueSheetContent()),
            if (song != null) ...[
              SeekBar(key: ValueKey(song.id)),
              const SizedBox(height: AppSpacing.md),
              const PlayerControlsRow(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class QueueSheetContent extends ConsumerWidget {
  const QueueSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final songs = ref.watch(playerProvider.select((state) => state.songs));
    final currentIndex = ref.watch(
      playerProvider.select((state) => state.index),
    );

    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.queueTitle),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.queueEmpty,
              style: AppTypography.body.copyWith(color: colors.textMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.backTooltip,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                l10n.queueTitle,
                style: AppTypography.playerTitle.copyWith(
                  color: colors.textHigh,
                ),
              ),
            ),
            Text(
              '${currentIndex + 1}/${songs.length}',
              style: AppTypography.caption.copyWith(color: colors.textMedium),
            ),
            IconButton(
              tooltip: l10n.clearQueueTooltip,
              icon: const Icon(Icons.playlist_remove_rounded),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(playerProvider.notifier).clearQueue();
              },
            ),
          ],
        ),
        Divider(height: 1, color: colors.outline),
        Expanded(
          child: ReorderableListView.builder(
            physics: const ClampingScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: songs.length,
            onReorderItem: (oldIndex, newIndex) => ref
                .read(playerProvider.notifier)
                .reorderQueue(oldIndex, newIndex),
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrent = index == currentIndex;
              return Padding(
                key: ValueKey(song.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Material(
                  color: isCurrent
                      ? colors.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: AppRadius.md,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    leading: ArtworkImage(songId: song.id),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isCurrent ? colors.primary : colors.textHigh,
                      ),
                    ),
                    subtitle: Text(
                      '${song.artist.isEmpty ? l10n.unknownArtist : song.artist} · ${song.duration.mmss}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        color: colors.textMedium,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.removeFromQueueTooltip,
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                          ),
                          onPressed: () => ref
                              .read(playerProvider.notifier)
                              .removeFromQueue(song.id),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Tooltip(
                            message: l10n.reorderQueueTooltip,
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Icon(Icons.drag_handle_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(playerProvider.notifier).jumpToQueueIndex(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
