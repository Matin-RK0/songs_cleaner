import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/application/providers/player_controller.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/song.dart';
import 'artwork_image.dart';
import '../../../../core/widgets/music_track_card.dart';

class SongTile extends ConsumerWidget {
  static const double itemExtent = 80;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isCurrent = false,
    this.showArtwork = true,
    this.onDeleteDevice,
    this.onAddToPlaylist,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.trailingLabel,
    this.onShowInfo,
    this.selected = false,
    this.onSelectionLongPress,
    this.onPreview,
    this.artwork,
    this.trailing,
    this.subtitle,
    this.progress,
    this.showMoreButton = false,
    this.extraActions = const [],
  });

  final Song song;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool showArtwork;
  final ValueChanged<Song>? onDeleteDevice;
  final ValueChanged<Song>? onAddToPlaylist;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final String? trailingLabel;
  final VoidCallback? onShowInfo;
  final bool selected;
  final VoidCallback? onSelectionLongPress;
  final VoidCallback? onPreview;
  final Widget? artwork;
  final Widget? trailing;
  final Widget? subtitle;
  final Widget? progress;
  final bool showMoreButton;
  final List<({IconData icon, String label, VoidCallback action})> extraActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    // Animate the equalizer only while playback is actually running; pausing
    // a song freezes the bars (they hold their last height) instead of
    // continuing to bob.
    final playing =
        isCurrent && ref.watch(playerProvider.select((state) => state.playing));
    final trailing =
        this.trailing ??
        (selected
            ? SizedBox.square(
                dimension: kMinInteractiveDimension,
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary,
                  ),
                ),
              )
            : onPreview != null
            ? IconButton(
                tooltip: l10n.playTooltip,
                onPressed: onPreview,
                icon: const Icon(Icons.play_circle_outline_rounded),
              )
            : showMoreButton
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrent) _FakeEqualizer(playing: playing),
                  IconButton(
                    tooltip: l10n.moreActions,
                    onPressed: () => _showActions(context, ref),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              )
            : isCurrent
            ? _FakeEqualizer(playing: playing)
            : trailingLabel == null
            ? null
            : Text(
                trailingLabel!,
                style: AppTypography.captionSmall.copyWith(
                  color: colors.textLow,
                ),
              ));
    return MusicTrackCard(
      title: song.title,
      subtitle:
          subtitle ??
          Text(
            '${song.artist.isEmpty ? l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      artwork: showArtwork
          ? artwork ??
                _ArtworkLeading(
                  songId: song.id,
                  isCurrent: isCurrent,
                  semanticLabel: song.title,
                )
          : null,
      trailing: trailing,
      progress: progress,
      isCurrent: isCurrent,
      selected: selected,
      onTap: onTap,
      onLongPress: onSelectionLongPress ?? () => _showActions(context, ref),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final extra in extraActions)
              ListTile(
                leading: Icon(extra.icon),
                title: Text(extra.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  extra.action();
                },
              ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(l10n.playTooltipShort),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onTap();
              },
            ),
            if (onShowInfo != null)
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.songDetailsTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onShowInfo!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: Text(l10n.playNext),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(playerProvider.notifier).playNext(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(l10n.addToQueue),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(playerProvider.notifier).addToQueue(song);
              },
            ),
            if (onAddToPlaylist != null)
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: Text(l10n.addToPlaylist),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onAddToPlaylist!(song);
                },
              ),
            if (onToggleFavorite != null)
              ListTile(
                leading: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                iconColor: colors.danger,
                title: Text(
                  isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onToggleFavorite!();
                },
              ),
            if (onDeleteDevice != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                iconColor: colors.danger,
                textColor: colors.danger,
                title: Text(l10n.deleteAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDeleteDevice!(song);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkLeading extends StatelessWidget {
  const _ArtworkLeading({
    required this.songId,
    required this.isCurrent,
    required this.semanticLabel,
  });

  final int songId;
  final bool isCurrent;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    const artworkSize = AppSpacing.trackArtwork;
    final artwork = ArtworkImage(
      songId: songId,
      size: isCurrent ? artworkSize - (AppSpacing.xs * 2) : artworkSize,
      borderRadius: isCurrent ? AppRadius.md : AppRadius.lg,
      semanticLabel: semanticLabel,
    );

    if (!isCurrent) {
      return Hero(tag: 'song-details-art-$songId', child: artwork);
    }

    return SizedBox.square(
      dimension: artworkSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: context.colors.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Hero(tag: 'song-details-art-$songId', child: artwork),
        ),
      ),
    );
  }
}

/// Lightweight animated equalizer shown beside the active song. The bars bob
/// only while playback is "playing"; pausing freezes them in place (the
/// controller is stopped without resetting, so the bars keep their last
/// height rather than collapsing).
class _FakeEqualizer extends StatefulWidget {
  const _FakeEqualizer({required this.playing});

  final bool playing;

  @override
  State<_FakeEqualizer> createState() => _FakeEqualizerState();
}

class _FakeEqualizerState extends State<_FakeEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _barOne;
  late final Animation<double> _barTwo;
  late final Animation<double> _barThree;
  late final CurvedAnimation _curve;
  bool _startScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
    _barOne = _bar(0.35, 1);
    _barTwo = _bar(0.8, 0.3);
    _barThree = _bar(0.5, 0.95);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant _FakeEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      _syncPlayback();
    }
  }

  /// Starts the loop while playing and stops it (holding the current bar
  /// heights) while paused. Repeated forwarding is harmless.
  void _syncPlayback() {
    if (widget.playing &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        ModalRoute.of(context)?.isCurrent != false) {
      if (_controller.isAnimating || _startScheduled) return;
      _startScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startScheduled = false;
        if (mounted &&
            widget.playing &&
            TickerMode.valuesOf(context).enabled &&
            !MediaQuery.disableAnimationsOf(context) &&
            ModalRoute.of(context)?.isCurrent != false) {
          _controller.repeat(reverse: true);
        }
      });
    } else {
      _controller.stop();
    }
  }

  Animation<double> _bar(double begin, double end) =>
      Tween<double>(begin: begin, end: end).animate(_curve);

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = context.colors.primary;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => SizedBox(
          width: 20,
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _barWidget(_barOne.value, barColor),
              const SizedBox(width: 2),
              _barWidget(_barTwo.value, barColor),
              const SizedBox(width: 2),
              _barWidget(_barThree.value, barColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barWidget(double factor, Color color) => Transform.scale(
    scaleY: factor,
    alignment: Alignment.bottomCenter,
    child: Container(
      width: AppSpacing.xs,
      height: AppSpacing.lg - AppSpacing.xs,
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
    ),
  );
}
