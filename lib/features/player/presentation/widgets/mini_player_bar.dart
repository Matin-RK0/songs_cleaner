import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';

/// Compact bar docked above the bottom edge; taps open the full player.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final song = ref.watch(
      playerProvider.select((state) => state.current),
    );
    if (song == null) return const SizedBox.shrink();

    final playing =
        ref.watch(playerProvider.select((state) => state.playing));
    final progress = ref.watch(playerProvider.select((state) {
      if (state.duration <= Duration.zero) return 0.0;
      final value =
          state.position.inMilliseconds / state.duration.inMilliseconds;
      return value.clamp(0.0, 1.0);
    }));

    return Material(
      color: AppColors.surfaceHigh,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.player),
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    ArtworkImage(songId: song.id, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist.isEmpty
                                ? l10n.unknownArtist
                                : song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          playing ? l10n.pauseTooltip : l10n.playTooltip,
                      onPressed: () => ref
                          .read(playerProvider.notifier)
                          .playPause(),
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.textHigh,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.nextTooltip,
                      onPressed: () =>
                          ref.read(playerProvider.notifier).next(),
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: AppColors.outline,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
