import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';
import '../../domain/playback_enums.dart';
import '../widgets/player_state_views.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/seek_bar.dart';

/// Full-screen now-playing view with the signature "clean this song" button.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.playerGradientTop,
              AppColors.playerGradientMiddle,
              AppColors.background,
            ],
            stops: [0.0, 0.42, 0.78],
          ),
        ),
        child: SafeArea(
          child: song == null
              ? const NothingPlayingView()
              : Column(
                  children: [
                    const _HeaderBar(),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: ArtworkImage(
                            songId: song.id,
                            size: _artworkSize(context),
                            borderRadius: AppRadius.xl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _TrackInfo(),
                    const SizedBox(height: AppSpacing.sm),
                    const SeekBar(),
                    const SizedBox(height: AppSpacing.md),
                    const _ControlsRow(),
                    const SizedBox(height: AppSpacing.md),
                    _DeleteCurrentButton(song: song),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
        ),
      ),
    );
  }

  static double _artworkSize(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest - AppSpacing.xl * 2).clamp(200.0, 360.0);
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.backTooltip,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        IconButton(
          tooltip: l10n.queueTitle,
          icon: const Icon(Icons.queue_music_rounded),
          onPressed: () => showQueueSheet(context),
        ),
      ],
    );
  }
}

class _TrackInfo extends ConsumerWidget {
  const _TrackInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(
      playerProvider.select((state) => state.current),
    );
    if (song == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            song.artist.isEmpty ? l10n.unknownArtist : song.artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsRow extends ConsumerWidget {
  const _ControlsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playing =
        ref.watch(playerProvider.select((state) => state.playing));
    final shuffled =
        ref.watch(playerProvider.select((state) => state.shuffled));
    final repeatMode =
        ref.watch(playerProvider.select((state) => state.repeatMode));

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
            onPressed: () =>
                ref.read(playerProvider.notifier).toggleShuffle(),
            icon: Icon(
              Icons.shuffle_rounded,
              size: 26,
              color: shuffled ? AppColors.primary : AppColors.textMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.previousTooltip,
            onPressed: () =>
                ref.read(playerProvider.notifier).previous(),
            icon: const Icon(
              Icons.skip_previous_rounded,
              size: 36,
              color: AppColors.textHigh,
            ),
          ),
          DecoratedBox(
            decoration: const ShapeDecoration(
              color: AppColors.primary,
              shape: CircleBorder(),
            ),
            child: IconButton.filled(
              tooltip: playing ? l10n.pauseTooltip : l10n.playTooltip,
              onPressed: () =>
                  ref.read(playerProvider.notifier).playPause(),
              icon: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Icon(
                  playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey(playing),
                  size: 34,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextTooltip,
            onPressed: () => ref.read(playerProvider.notifier).next(),
            icon: const Icon(
              Icons.skip_next_rounded,
              size: 36,
              color: AppColors.textHigh,
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
                  ? AppColors.textMedium
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteCurrentButton extends ConsumerWidget {
  const _DeleteCurrentButton({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger.withValues(alpha: 0.16),
            foregroundColor: AppColors.danger,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.45)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: () => deleteSongFlow(context, ref, song),
          icon: const Icon(Icons.delete_forever_rounded, size: 22),
          label: Text(l10n.deleteAction),
        ),
      ),
    );
  }
}
