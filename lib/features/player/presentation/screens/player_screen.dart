import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/player_controller.dart';
import '../widgets/delete_current_button.dart';
import '../widgets/player_controls_row.dart';
import '../widgets/player_state_views.dart';
import '../widgets/player_track_info.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/seek_bar.dart';
import '../widgets/swipe_down_to_dismiss.dart';

/// Full-screen now-playing view with the signature "clean this song" button.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));

    return SwipeDownToDismiss(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: ColoredBox(
          color: AppColors.surface,
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
                      const PlayerTrackInfo(),
                      const SizedBox(height: AppSpacing.sm),
                      const SeekBar(),
                      const SizedBox(height: AppSpacing.md),
                      const PlayerControlsRow(),
                      const SizedBox(height: AppSpacing.xl),
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
    return (shortest - AppSpacing.xl * 2).clamp(200.0, 360.0);
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
          const Spacer(),
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
