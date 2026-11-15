import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import 'delete_current_button.dart';
import 'player_controls_row.dart';
import 'player_track_info.dart';
import 'seek_bar.dart';

/// Identical responsive composition on the player and keyguard routes.
class PlayerLayout extends StatelessWidget {
  const PlayerLayout({
    super.key,
    required this.song,
    required this.header,
    required this.actions,
    required this.hideQuickDelete,
    this.useHero = false,
  });

  final Song song;
  final Widget header;
  final Widget actions;
  final bool hideQuickDelete;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final minimum =
            AppPlayerMetrics.minimumHeight +
            (hideQuickDelete ? 0 : AppPlayerMetrics.deleteExtent) +
            math.max(0, textScale - 1) * AppPlayerMetrics.chromeHeight;
        final height = math.max(constraints.maxHeight, minimum);
        final artworkSize = math.min(
          math.max(
            AppPlayerMetrics.artworkMin,
            constraints.maxWidth - AppSpacing.xl * 2,
          ),
          math.min(
            AppPlayerMetrics.artworkMax,
            math.max(
              AppPlayerMetrics.artworkMin,
              height -
                  AppPlayerMetrics.chromeHeight -
                  (hideQuickDelete ? 0 : AppPlayerMetrics.deleteExtent) -
                  math.max(0, textScale - 1) * AppPlayerMetrics.chromeHeight,
            ),
          ),
        );
        final artwork = ArtworkImage(
          songId: song.id,
          size: artworkSize,
          borderRadius: AppRadius.xl,
        );
        final content = SizedBox(
          height: height,
          child: Column(
            children: [
              header,
              const SizedBox(height: AppSpacing.md),
              RepaintBoundary(
                child: useHero
                    ? Hero(tag: 'song-artwork-${song.id}', child: artwork)
                    : artwork,
              ),
              const SizedBox(height: AppSpacing.lg),
              PlayerTrackInfo(song: song),
              const Spacer(),
              actions,
              const SizedBox(height: AppSpacing.sm),
              SeekBar(key: ValueKey(song.id)),
              const SizedBox(height: AppSpacing.md),
              const PlayerControlsRow(),
              if (!hideQuickDelete) ...[
                const SizedBox(height: AppSpacing.lg),
                DeleteCurrentButton(
                  key: ValueKey('delete-${song.id}'),
                  song: song,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
        if (constraints.maxHeight >= minimum) return content;
        // Landscape, small devices and large accessibility text stay reachable.
        return SingleChildScrollView(child: content);
      },
    );
  }
}
