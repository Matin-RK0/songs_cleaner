import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';

/// Compact bar docked above the bottom edge; taps open the full player.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  static const double height = 130;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
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

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _MiniPlayerGestures(
          onPrevious: () => ref.read(playerProvider.notifier).previous(),
          onNext: () => ref.read(playerProvider.notifier).next(),
          child: Material(
            color: colors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: AppRadius.lg.topLeft),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: ArtworkImage(
                        key: ValueKey(song.id),
                        songId: song.id,
                        size: 300,
                        expand: true,
                        borderRadius: BorderRadius.vertical(
                          top: AppRadius.lg.topLeft,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: ColoredBox(color: colors.scrim)),
                Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: ListTile(
                        key: ValueKey(song.id),
                        onTap: () => AppRouter.openPlayer(context),
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.md,
                          0,
                          AppSpacing.sm,
                          0,
                        ),
                        splashColor: Colors.transparent,
                        leading: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: colors.primary.withValues(alpha: 0.24),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.lg,
                            ),
                          ),
                          child: Hero(
                            tag: 'song-artwork-${song.id}',
                            child: ArtworkImage(
                              songId: song.id,
                              size: 45,
                              borderRadius: AppRadius.lg,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.emphasisTitle.copyWith(
                            color: colors.onScrim,
                          ),
                        ),
                        subtitle: Text(
                          song.artist.isEmpty
                              ? l10n.unknownArtist
                              : song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.songSubtitle.copyWith(
                            color: colors.onScrimMuted,
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
                            tooltip: playing
                                ? l10n.pauseTooltip
                                : l10n.playTooltip,
                          ),
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
        ),
      ),
    );
  }
}

/// Adds track-change gestures to the docked mini player.
///
/// Horizontal flicks change the track.
/// The inner seek bar keeps its own horizontal drag handling and wins the
/// gesture arena for flicks that start on it.
class _MiniPlayerGestures extends StatefulWidget {
  const _MiniPlayerGestures({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  State<_MiniPlayerGestures> createState() => _MiniPlayerGesturesState();
}

class _MiniPlayerGesturesState extends State<_MiniPlayerGestures> {
  static const double _distanceThreshold = 56;
  static const double _velocityThreshold = 420;

  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) => _dx += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dx <= -_distanceThreshold || velocity <= -_velocityThreshold) {
          widget.onNext();
        } else if (_dx >= _distanceThreshold ||
            velocity >= _velocityThreshold) {
          widget.onPrevious();
        }
        _dx = 0;
      },
      child: widget.child,
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
    final colors = context.colors;
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
              backgroundColor: colors.scrimTrack,
              valueColor: AlwaysStoppedAnimation(colors.onScrim),
            ),
            Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: colors.onScrim,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSongProgress extends StatefulWidget {
  const _MiniSongProgress({required this.value, required this.onChanged});

  final double value;
  final Future<void> Function(double value) onChanged;

  @override
  State<_MiniSongProgress> createState() => _MiniSongProgressState();
}

class _MiniSongProgressState extends State<_MiniSongProgress> {
  double? _dragValue;
  bool _committing = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final value = _dragValue ?? widget.value;

        void update(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          setState(() {
            _dragValue = (localPosition.dx / constraints.maxWidth).clamp(
              0.0,
              1.0,
            );
          });
        }

        Future<void> commit() async {
          final target = _dragValue;
          if (target == null || _committing) return;
          _committing = true;
          try {
            await widget.onChanged(target);
          } finally {
            if (mounted) {
              setState(() {
                _dragValue = null;
                _committing = false;
              });
            }
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => update(details.localPosition),
          onTapUp: (_) => commit(),
          onHorizontalDragEnd: (_) => commit(),
          onHorizontalDragUpdate: (details) => update(details.localPosition),
          child: SizedBox(
            height: 28,
            child: Center(
              child: LinearProgressIndicator(
                borderRadius: AppRadius.pill,
                value: value,
                minHeight: 4,
                backgroundColor: colors.scrimTrack,
                valueColor: AlwaysStoppedAnimation<Color>(colors.onScrim),
              ),
            ),
          ),
        );
      },
    );
  }
}
