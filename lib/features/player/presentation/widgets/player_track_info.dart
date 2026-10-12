import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/providers/player_controller.dart';

/// Title + artist block for the currently playing song. Shared by the normal
/// player screen and the lock-screen player.
class PlayerTrackInfo extends ConsumerWidget {
  const PlayerTrackInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    if (song == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.playerTitle.copyWith(
              color: colors.textHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            song.artist.isEmpty ? l10n.unknownArtist : song.artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.playerArtist.copyWith(
              color: colors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
