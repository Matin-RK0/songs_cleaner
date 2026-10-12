import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/delete_current_button.dart';
import '../../../player/presentation/widgets/player_controls_row.dart';
import '../../../player/presentation/widgets/player_state_views.dart';
import '../../../player/presentation/widgets/player_track_info.dart';
import '../../../player/presentation/widgets/seek_bar.dart';
import '../../application/providers/lock_screen_controller.dart';

/// Lock-screen player. Pushed by the lock-screen coordinator when the keyguard
/// turns on during playback, so the controls cover the lock screen instead of
/// the home screen. Back retreats to the keyguard via the native controller.
class LockScreenPlayerScreen extends ConsumerWidget {
  const LockScreenPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    final l10n = context.l10n;

    return PopScope(
      // The route is removed by the lock-screen coordinator (unlock or back);
      // after it is gone tell native to drop the over-keyguard window flags.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(lockScreenServiceProvider).dismiss();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            child: song == null
                ? const NothingPlayingView()
                : Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          tooltip: l10n.backTooltip,
                          iconSize: 30,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
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
                      const PlayerTrackInfo(),
                      const SizedBox(height: AppSpacing.sm),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: SeekBar(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const PlayerControlsRow(),
                      const SizedBox(height: AppSpacing.lg),
                      DeleteCurrentButton(song: song),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static double _artworkSize(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest - AppSpacing.xl * 2).clamp(180.0, 340.0);
  }
}
