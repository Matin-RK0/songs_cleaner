import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/providers/player_controller.dart';
import '../../domain/playback_enums.dart';

/// Transport controls row (shuffle, previous, play/pause, next, repeat).
/// Shared by the normal player screen and the lock-screen player.
class PlayerControlsRow extends ConsumerWidget {
  const PlayerControlsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final playing = ref.watch(playerProvider.select((state) => state.playing));
    final shuffled = ref.watch(
      playerProvider.select((state) => state.shuffled),
    );
    final repeatMode = ref.watch(
      playerProvider.select((state) => state.repeatMode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        // Playback order is physical: previous stays on the left and next on
        // the right, including when the app is displayed in an RTL locale.
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: l10n.shuffleTooltip,
            onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
            icon: Icon(
              Icons.shuffle_rounded,
              size: 26,
              color: shuffled ? colors.primary : colors.textMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.previousTooltip,
            onPressed: () => ref.read(playerProvider.notifier).previous(),
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 36,
              color: colors.textHigh,
            ),
          ),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.primary,
              shape: const CircleBorder(),
            ),
            child: IconButton.filled(
              tooltip: playing ? l10n.pauseTooltip : l10n.playTooltip,
              onPressed: () => ref.read(playerProvider.notifier).playPause(),
              icon: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(playing),
                  size: 34,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextTooltip,
            onPressed: () => ref.read(playerProvider.notifier).next(),
            icon: Icon(
              Icons.skip_next_rounded,
              size: 36,
              color: colors.textHigh,
            ),
          ),
          IconButton(
            tooltip: switch (repeatMode) {
              RepeatMode.off => l10n.repeatOffTooltip,
              RepeatMode.all => l10n.repeatAllTooltip,
              RepeatMode.one => l10n.repeatOneTooltip,
            },
            onPressed: () =>
                ref.read(playerProvider.notifier).cycleRepeatMode(),
            icon: Icon(
              switch (repeatMode) {
                RepeatMode.off => Icons.repeat_rounded,
                RepeatMode.all => Icons.repeat_rounded,
                RepeatMode.one => Icons.repeat_one_rounded,
              },
              size: 26,
              color: repeatMode == RepeatMode.off
                  ? colors.textMedium
                  : colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
