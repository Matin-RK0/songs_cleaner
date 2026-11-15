import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../application/providers/player_controller.dart';
import '../../domain/playback_enums.dart';
import 'player_icon.dart';

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
            iconSize: AppPlayerMetrics.icon,
            color: shuffled ? colors.primary : colors.textMedium,
            icon: const PlayerIcon(PlayerGlyph.shuffle),
          ),
          IconButton(
            tooltip: l10n.previousTooltip,
            onPressed: canSkip
                ? () => ref.read(playerProvider.notifier).previous()
                : null,
            iconSize: AppPlayerMetrics.skipIcon,
            color: colors.primary,
            disabledColor: colors.textLow,
            icon: const PlayerIcon(PlayerGlyph.previous),
          ),
          RepaintBoundary(
            child: IconButton(
              tooltip: playing ? l10n.pauseTooltip : l10n.playTooltip,
              onPressed: () => ref.read(playerProvider.notifier).playPause(),
              constraints: const BoxConstraints.tightFor(
                width: AppPlayerMetrics.transportExtent,
                height: AppPlayerMetrics.transportExtent,
              ),
              padding: EdgeInsets.zero,
              iconSize: AppPlayerMetrics.playIcon,
              color: colors.primary,
              icon: PlayerIcon(playing ? PlayerGlyph.pause : PlayerGlyph.play),
            ),
          ),
          IconButton(
            tooltip: l10n.nextTooltip,
            onPressed: canSkip
                ? () => ref.read(playerProvider.notifier).next()
                : null,
            iconSize: AppPlayerMetrics.skipIcon,
            color: colors.primary,
            disabledColor: colors.textLow,
            icon: const PlayerIcon(PlayerGlyph.next),
          ),
          IconButton(
            tooltip: switch (repeatMode) {
              RepeatMode.off => l10n.repeatOffTooltip,
              RepeatMode.all => l10n.repeatAllTooltip,
              RepeatMode.one => l10n.repeatOneTooltip,
            },
            onPressed: () =>
                ref.read(playerProvider.notifier).cycleRepeatMode(),
            iconSize: AppPlayerMetrics.icon,
            color: repeatMode == RepeatMode.off
                ? colors.textMedium
                : colors.primary,
            icon: PlayerIcon(
              repeatMode == RepeatMode.one
                  ? PlayerGlyph.repeatOne
                  : PlayerGlyph.repeat,
            ),
          ),
        ],
      ),
    );
  }
}
