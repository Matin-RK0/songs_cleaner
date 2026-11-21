import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';

/// Compact playback controls docked above the bottom safe area.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  static const _controlsHeight = AppSpacing.trackRowHeight;
  static const _seekHeight = AppSpacing.xl;
  static const double height = _controlsHeight + _seekHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    if (song == null) return const SizedBox.shrink();
    final canSkip = ref.watch(
      playerProvider.select((state) => state.canSkipTracks),
    );

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: context.colors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: AppRadius.lg.topLeft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: _CoverBackdrop(songId: song.id)),
              Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  children: [
                    SizedBox(
                      height: _controlsHeight,
                      child: _MiniPlayerGestures(
                        onPrevious: canSkip
                            ? () => ref.read(playerProvider.notifier).previous()
                            : null,
                        onNext: canSkip
                            ? () => ref.read(playerProvider.notifier).next()
                            : null,
                        child: Row(
                          children: [
                            Expanded(child: _TrackSummary(song: song)),
                            const SizedBox(width: AppSpacing.sm),
                            const _MiniPlayButton(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _seekHeight,
                      child: _MiniSeekBar(key: ValueKey(song.id)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverBackdrop extends ConsumerWidget {
  const _CoverBackdrop({required this.songId});

  final int songId;
  static const _sourceSize =
      500; // Shares MediaStore thumbnail bytes with the cover.
  static const _decodeWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = ref.watch(songArtworkProvider((songId, _sourceSize))).value;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null)
              Image.memory(
                cover,
                key: ValueKey(songId),
                fit: BoxFit.cover,
                cacheWidth: _decodeWidth,
                filterQuality: FilterQuality.low,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            const ColoredBox(color: AppColorTokens.miniPlayerScrim),
          ],
        ),
      ),
    );
  }
}

class _TrackSummary extends StatelessWidget {
  const _TrackSummary({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleStyle = AppTypography.emphasisTitle.copyWith(
      color: colors.onScrim,
    );
    final showArtist =
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize!) +
            MediaQuery.textScalerOf(context)
                .scale(AppTypography.songSubtitle.fontSize!) <=
        AppSpacing.trackArtwork;
    final artist = song.artist.isEmpty
        ? context.l10n.unknownArtist
        : song.artist;
    return InkWell(
      onTap: () => AppRouter.openPlayer(context),
      borderRadius: AppRadius.lg,
      child: Row(
        children: [
          Hero(
            tag: 'song-artwork-${song.id}',
            child: ArtworkImage(
              songId: song.id,
              size: AppSpacing.avatarSize,
              borderRadius: AppRadius.md,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                if (showArtist) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Flexible(
                    child: Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.songSubtitle.copyWith(
                        color: colors.onScrimMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayButton extends ConsumerWidget {
  const _MiniPlayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerProvider.select((state) => state.playing));
    final colors = context.colors;
    return IconButton(
      tooltip: playing ? context.l10n.pauseTooltip : context.l10n.playTooltip,
      onPressed: () => ref.read(playerProvider.notifier).playPause(),
      icon: Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: colors.onScrim,
      ),
      style: IconButton.styleFrom(backgroundColor: colors.scrimTrack),
    );
  }
}

/// Only the seek strip listens to position changes; the cover and text stay static.
class _MiniSeekBar extends ConsumerStatefulWidget {
  const _MiniSeekBar({super.key});

  @override
  ConsumerState<_MiniSeekBar> createState() => _MiniSeekBarState();
}

class _MiniSeekBarState extends ConsumerState<_MiniSeekBar> {
  double? _dragValue;
  bool _committing = false;

  Future<void> _commit() async {
    final target = _dragValue;
    if (target == null || _committing) return;
    _committing = true;
    try {
      final duration = ref.read(playerProvider).duration;
      await ref.read(playerProvider.notifier).seek(duration * target);
    } finally {
      if (mounted) {
        setState(() {
          _dragValue = null;
          _committing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (progress, seekable) = ref.watch(
      playerProvider.select((state) {
        final total = state.duration.inMilliseconds;
        if (total <= 0) return (0.0, false);
        return ((state.position.inMilliseconds / total).clamp(0.0, 1.0), true);
      }),
    );
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          void update(Offset point) {
            if (_committing || constraints.maxWidth <= 0) return;
            final fraction = (point.dx / constraints.maxWidth).clamp(0.0, 1.0);
            setState(() => _dragValue = rtl ? 1 - fraction : fraction);
          }

          void cancel() {
            if (!_committing && _dragValue != null) {
              setState(() => _dragValue = null);
            }
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: seekable
                ? (details) {
                    update(details.localPosition);
                    _commit();
                  }
                : null,
            onHorizontalDragStart: seekable
                ? (details) => update(details.localPosition)
                : null,
            onHorizontalDragUpdate: seekable
                ? (details) => update(details.localPosition)
                : null,
            onHorizontalDragEnd: seekable ? (_) => _commit() : null,
            onHorizontalDragCancel: seekable ? cancel : null,
            child: Center(
              child: LinearProgressIndicator(
                borderRadius: AppRadius.pill,
                value: _dragValue ?? progress,
                minHeight: AppSpacing.xs,
                backgroundColor: colors.scrimTrack,
                valueColor: AlwaysStoppedAnimation(colors.onScrim),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal flicks on the summary row change the track, not the seek position.
class _MiniPlayerGestures extends StatefulWidget {
  const _MiniPlayerGestures({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
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
    if (widget.onNext == null && widget.onPrevious == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (details) => _dx += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dx <= -_distanceThreshold || velocity <= -_velocityThreshold) {
          widget.onNext?.call();
        } else if (_dx >= _distanceThreshold ||
            velocity >= _velocityThreshold) {
          widget.onPrevious?.call();
        }
      },
      child: widget.child,
    );
  }
}
