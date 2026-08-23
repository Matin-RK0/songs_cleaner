import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../application/providers/player_controller.dart';

/// Bottom sheet listing the active play queue.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.75,
    ),
    builder: (_) => const QueueSheetContent(),
  );
}

class QueueSheetContent extends ConsumerWidget {
  const QueueSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final songs = ref.watch(playerProvider.select((state) => state.songs));
    final currentIndex =
        ref.watch(playerProvider.select((state) => state.index));

    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.queueTitle),
            const SizedBox(height: 16),
            Text(
              l10n.queueEmpty,
              style: const TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                l10n.queueTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHigh,
                ),
              ),
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
        const Divider(height: 1, color: AppColors.outline),
        Expanded(
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrent = index == currentIndex;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                leading: isCurrent
                    ? const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.primary,
                      )
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.textLow,
                          fontSize: 12,
                        ),
                      ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textHigh,
                  ),
                ),
                subtitle: Text(
                  '${song.artist.isEmpty ? l10n.unknownArtist : song.artist} · ${song.duration.mmss}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5),
                ),
                trailing: IconButton(
                  tooltip: l10n.removeFromQueueTooltip,
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(playerProvider.notifier)
                      .removeFromQueue(song.id),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(playerProvider.notifier)
                      .jumpToQueueIndex(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
