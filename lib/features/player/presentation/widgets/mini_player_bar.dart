import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';

/// Compact bar docked above the bottom edge; taps open the full player.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  static const double height = 130;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final song = ref.watch(playerProvider.select((state) => state.current));
    if (song == null) return const SizedBox.shrink();

    final playing = ref.watch(playerProvider.select((state) => state.playing));
    final progress = ref.watch(
      playerProvider.select((state) {
        if (state.duration <= Duration.zero) return 0.0;
        final value =
            state.position.inMilliseconds / state.duration.inMilliseconds;
        return value.clamp(0.0, 1.0);
      }),
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: AppColors.surfaceHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ArtworkImage(
                songId: song.id,
                size: 300,
                expand: true,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
            const Positioned.fill(child: ColoredBox(color: Colors.black54)),
            Stack(
              children: [
                ListTile(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.player),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.sm,
                    0,
                  ),
                  splashColor: Colors.transparent,
                  leading: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
                    ),
                    child: ArtworkImage(
                      songId: song.id,
                      size: 45,
                      borderRadius: AppRadius.lg,
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHigh,
                    ),
                  ),
                  subtitle: Text(
                    song.artist.isEmpty ? l10n.unknownArtist : song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMedium,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 50,
                    height: 50,
                    child: _PlayPauseProgress(
                      progress: progress,
                      playing: playing,
                      onPressed: () =>
                          ref.read(playerProvider.notifier).playPause(),
                      tooltip: playing ? l10n.pauseTooltip : l10n.playTooltip,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    title: _MiniSongProgress(
                      value: progress,
                      onChanged: (value) => ref
                          .read(playerProvider.notifier)
                          .seek(
                            Duration(
                              milliseconds:
                                  (value *
                                          ref
                                              .read(playerProvider)
                                              .duration
                                              .inMilliseconds)
                                      .round(),
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseProgress extends StatelessWidget {
  const _PlayPauseProgress({
    required this.progress,
    required this.playing,
    required this.onPressed,
    required this.tooltip,
  });

  final double progress;
  final bool playing;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      icon: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
            Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.textHigh,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSongProgress extends StatelessWidget {
  const _MiniSongProgress({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void update(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          onChanged((localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => update(details.localPosition),
          onHorizontalDragUpdate: (details) => update(details.localPosition),
          child: SizedBox(
            height: 28,
            child: Center(
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(16),
                value: value,
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
