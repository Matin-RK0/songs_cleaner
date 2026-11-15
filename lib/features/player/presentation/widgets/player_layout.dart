import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/domain/entities/song.dart';
import '../../../lockscreen/presentation/widgets/lock_screen_background.dart';
import 'delete_current_button.dart';
import 'artwork_ambient_background.dart';
import 'player_controls_row.dart';
import 'player_artwork_and_info.dart';
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
        final deleteSpace = hideQuickDelete
            ? 0.0
            : AppPlayerMetrics.deleteExtent -
                  (AppPlayerMetrics.bottomSpace - AppSpacing.lg);
        final minimum =
            AppPlayerMetrics.minimumHeight +
            deleteSpace +
            math.max(0, textScale - 1) * AppPlayerMetrics.chromeHeight;
        final height = math.max(constraints.maxHeight, minimum);
        final artworkSize = math.min(
          math.max(
            AppPlayerMetrics.artworkMin,
            constraints.maxWidth * AppPlayerMetrics.artworkWidthFraction,
          ),
          math.min(
            AppPlayerMetrics.artworkMax,
            math.max(
              AppPlayerMetrics.artworkMin,
              height -
                  AppPlayerMetrics.chromeHeight -
                  deleteSpace -
                  math.max(0, textScale - 1) * AppPlayerMetrics.chromeHeight,
            ),
          ),
        );
        final content = SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                // Keep the upper area dark in both playback states. The largest
                // cover bounds are stable, so resizing never animates a clip.
                top:
                    AppSpacing.lg +
                    AppPlayerMetrics.touchExtent +
                    AppSpacing.md +
                    artworkSize,
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: ClipRect(
                    child: ArtworkAmbientBackground(
                      songId: song.id,
                      visible: true,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  header,
                  const SizedBox(height: AppSpacing.md),
                  ScreenLockDoubleTapRegion(
                    child: PlayerArtworkAndInfo(
                      song: song,
                      artworkSize: artworkSize,
                      useHero: useHero,
                    ),
                  ),
                  const Expanded(
                    child: ScreenLockDoubleTapRegion(child: SizedBox.expand()),
                  ),
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
                  SizedBox(
                    height: hideQuickDelete
                        ? AppPlayerMetrics.bottomSpace
                        : AppSpacing.lg,
                  ),
                ],
              ),
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
