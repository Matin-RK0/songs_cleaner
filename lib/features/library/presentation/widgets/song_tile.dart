import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
  });

  final Song song;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool showArtwork;
  final ValueChanged<Song>? onDeleteDevice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Material(
        // Keep the selected row's surface identical to every other row;
        // the active title and equalizer provide the playback indication.
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onDeleteDevice == null
              ? null
              : () => _showActions(context),
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: isCurrent ? AppColors.primary : AppColors.textHigh,
              ),
            ),
            subtitle: Text(
              '${song.artist.isEmpty ? l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMedium,
              ),
            ),
            trailing: isCurrent ? const _FakeEqualizer() : null,
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = context.l10n;
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
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              title: Text(l10n.deleteAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDeleteDevice?.call(song);
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
            side: const BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
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

/// Lightweight animated equalizer shown beside the active song.
class _FakeEqualizer extends StatefulWidget {
  const _FakeEqualizer();

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
    _controller = AnimationController(vsync: this, duration: AppMotion.slow)
      ..repeat(reverse: true);
    _barOne = _bar(0.35, 1);
    _barTwo = _bar(0.8, 0.3);
    _barThree = _bar(0.5, 0.95);
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
              _barWidget(_barOne.value),
              const SizedBox(width: 2),
              _barWidget(_barTwo.value),
              const SizedBox(width: 2),
              _barWidget(_barThree.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barWidget(double factor) => Container(
    width: 4,
    height: 20 * factor,
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: AppRadius.pill,
    ),
  );
}
