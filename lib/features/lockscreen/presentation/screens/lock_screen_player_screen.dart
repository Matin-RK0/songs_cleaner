import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/application/providers/player_preferences_controller.dart';
import '../../../player/presentation/widgets/artwork_ambient_background.dart';
import '../../../player/presentation/widgets/player_actions.dart';
import '../../../player/presentation/widgets/player_layout.dart';
import '../../../player/presentation/widgets/player_state_views.dart';
import '../../application/providers/lock_screen_controller.dart';
import '../widgets/lock_screen_background.dart';

/// Keep the keyguard covered until native confirms successful authentication.
class LockScreenPlayerScreen extends ConsumerWidget {
  const LockScreenPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    final hideQuickDelete = ref.watch(hideQuickDeleteProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(lockScreenServiceProvider).dismiss();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: ArtworkAmbientBackground(
          subdued: true,
          songId: song?.id,
          visible: song != null,
          child: LockScreenBackground(
            child: SafeArea(
              child: song == null
                  ? const NothingPlayingView()
                  : PlayerLayout(
                      song: song,
                      hideQuickDelete: hideQuickDelete,
                      actions: PlayerActions(song: song, locked: true),
                      header: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: context.l10n.backTooltip,
                              iconSize: AppPlayerMetrics.icon,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              onPressed: () =>
                                  ref.read(lockScreenServiceProvider).dismiss(),
                            ),
                            const Spacer(),
                            const Icon(Icons.lock_outline_rounded),
                            const SizedBox(width: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
