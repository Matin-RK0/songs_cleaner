import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../application/providers/player_controller.dart';
import '../../application/providers/player_preferences_controller.dart';
import '../widgets/delete_current_button.dart';
import '../widgets/artwork_ambient_background.dart';
import '../widgets/player_controls_row.dart';
import '../widgets/player_state_views.dart';
import '../widgets/player_track_info.dart';
import '../widgets/playback_options_sheet.dart';
import '../../../../app/router/route_names.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/seek_bar.dart';
import '../widgets/swipe_down_to_dismiss.dart';

/// Full-screen now-playing view with the signature "clean this song" button.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    final hideQuickDelete = ref.watch(hideQuickDeleteProvider);
    return SwipeDownToDismiss(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: ArtworkAmbientBackground(
          songId: song?.id,
          visible: song != null,
          child: SafeArea(
            child: song == null
                ? const NothingPlayingView()
                : Column(
                    children: [
                      const _HeaderBar(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: RepaintBoundary(
                                    child: AnimatedSwitcher(
                                      duration:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? Duration.zero
                                          : AppMotion.normal,
                                      switchInCurve: AppMotion.standard,
                                      switchOutCurve: AppMotion.standard,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                      child: Hero(
                                        key: ValueKey(song.id),
                                        tag: 'song-artwork-${song.id}',
                                        child: ArtworkImage(
                                          songId: song.id,
                                          size: _artworkSize(
                                            context,
                                            constraints.maxHeight,
                                          ),
                                          borderRadius: AppRadius.xl,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              RepaintBoundary(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : AppMotion.normal,
                                  switchInCurve: AppMotion.standard,
                                  switchOutCurve: AppMotion.standard,
                                  child: PlayerTrackInfo(
                                    key: ValueKey(song.id),
                                    song: song,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SeekBar(key: ValueKey(song.id)),
                              const SizedBox(height: AppSpacing.xs),
                              const PlayerControlsRow(),
                              const SizedBox(height: AppSpacing.xs),
                              _PlayerActions(song: song),
                              if (!hideQuickDelete) ...[
                                const SizedBox(height: AppSpacing.xs),
                                DeleteCurrentButton(song: song),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static double _artworkSize(BuildContext context, double availableHeight) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final widthBased = shortest - AppSpacing.xl * 2;
    final heightBased = (availableHeight * 0.72).clamp(120.0, 340.0);
    return widthBased.clamp(120.0, heightBased).toDouble();
  }
}

class _PlayerActions extends ConsumerWidget {
  const _PlayerActions({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isFavorite = ref.watch(
      libraryStatsProvider.select((stats) => stats.isFavorite(song.id)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionIcon(
            tooltip: isFavorite
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
            icon: isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavorite ? colors.danger : colors.textMedium,
            onPressed: () =>
                ref.read(libraryStatsProvider.notifier).toggleFavorite(song.id),
          ),
          _ActionIcon(
            tooltip: l10n.addToPlaylist,
            icon: Icons.playlist_add_rounded,
            onPressed: () => showAddToPlaylistSheet(context, song),
          ),
          _ActionIcon(
            tooltip: l10n.playbackOptionsTitle,
            icon: Icons.tune_rounded,
            onPressed: () => showPlaybackOptionsSheet(context, ref),
          ),
          _ActionIcon(
            tooltip: l10n.lyricsTitle,
            icon: Icons.lyrics_outlined,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(RouteNames.lyrics, arguments: song),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 24,
        color: color ?? context.colors.textMedium,
        splashRadius: 24,
        icon: AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(icon, key: ValueKey(icon)),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.backTooltip,
            iconSize: 30,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              l10n.playerScreenTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sectionTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.textHigh,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.queueTitle,
            iconSize: 30,
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => showQueueSheet(context),
          ),
        ],
      ),
    );
  }
}
