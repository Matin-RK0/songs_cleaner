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

class SongTile extends ConsumerWidget {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    // Animate the equalizer only while playback is actually running; pausing
    // a song freezes the bars (they hold their last height) instead of
    // continuing to bob.
    final playing =
        isCurrent && ref.watch(playerProvider.select((state) => state.playing));
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Material(
        // Keep the selected row's surface identical to every other row;
        // the active title and equalizer provide the playback indication.
        color: selected ? colors.surfaceHigh : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onSelectionLongPress ?? () => _showActions(context, ref),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            minVerticalPadding: 0,
            leading: showArtwork
                ? _ArtworkLeading(songId: song.id, isCurrent: isCurrent)
                : const SizedBox(width: AppSpacing.sm),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.songTitle.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: isCurrent ? colors.primary : colors.textHigh,
              ),
            ),
            subtitle: Text(
              '${song.artist.isEmpty ? l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.songSubtitle.copyWith(
                color: colors.textMedium,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: colors.primary)
                : isCurrent
                ? _FakeEqualizer(playing: playing)
                : trailingLabel == null
                ? null
                : Text(
                    trailingLabel!,
                    style: AppTypography.captionSmall.copyWith(
                      color: colors.textLow,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
  const _ArtworkLeading({required this.songId, required this.isCurrent});

  final int songId;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    const artworkSize = 56.0;
    final artwork = ArtworkImage(
      songId: songId,
      size: isCurrent ? artworkSize - (AppSpacing.xs * 2) : artworkSize,
      borderRadius: isCurrent ? AppRadius.md : AppRadius.lg,
    );

    if (!isCurrent) return artwork;

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
          child: artwork,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _barOne = _bar(0.35, 1);
    _barTwo = _bar(0.8, 0.3);
    _barThree = _bar(0.5, 0.95);
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
    if (widget.playing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  Animation<double> _bar(double begin, double end) => Tween<double>(
    begin: begin,
    end: end,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
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

  Widget _barWidget(double factor, Color color) => Container(
    width: 4,
    height: 20 * factor,
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
  );
}
