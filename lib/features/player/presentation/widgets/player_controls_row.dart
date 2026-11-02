import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/providers/player_controller.dart';
import '../../domain/playback_enums.dart';

/// Transport controls shared by the full and lock-screen players.
class PlayerControlsRow extends ConsumerWidget {
  const PlayerControlsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final playing = ref.watch(playerProvider.select((state) => state.playing));
    final canSkip = ref.watch(
      playerProvider.select((state) => state.canSkipTracks),
    );
    final shuffled = ref.watch(
      playerProvider.select((state) => state.shuffled),
    );
    final repeatMode = ref.watch(
      playerProvider.select((state) => state.repeatMode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
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
            onPressed: canSkip
                ? () => ref.read(playerProvider.notifier).previous()
                : null,
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 36,
              color: canSkip ? colors.textHigh : colors.textLow,
            ),
          ),
          RepaintBoundary(
            child: AnimatedScale(
              scale: playing ? 1 : 0.94,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.primary,
                  shape: const CircleBorder(),
                  shadows: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: playing ? l10n.pauseTooltip : l10n.playTooltip,
                  onPressed: () =>
                      ref.read(playerProvider.notifier).playPause(),
                  constraints: const BoxConstraints.tightFor(
                    width: 68,
                    height: 68,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: 38,
                  icon: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey(playing),
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextTooltip,
            onPressed: canSkip
                ? () => ref.read(playerProvider.notifier).next()
                : null,
            icon: Icon(
              Icons.skip_next_rounded,
              size: 36,
              color: canSkip ? colors.textHigh : colors.textLow,
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
