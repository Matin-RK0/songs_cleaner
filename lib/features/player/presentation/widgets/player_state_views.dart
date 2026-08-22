import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../application/providers/player_controller.dart';

/// Shown when playback is idle (e.g. inside the player screen).
class NothingPlayingView extends StatelessWidget {
  const NothingPlayingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.music_off_rounded,
      title: context.l10n.nothingPlayingTitle,
    );
  }
}

/// Shows a snackbar for songs whose files failed to load.
class PlayerErrorListener extends ConsumerWidget {
  const PlayerErrorListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(playbackErrorEventsProvider, (previous, next) {
      next.whenData((title) {
        showAppSnackBar(
          context,
          context.l10n.playbackFailedToast(title),
          error: true,
        );
      });
    });
    return child;
  }
}
