import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/domain/entities/song.dart';

/// Title + artist block for the currently playing song. Shared by the normal
/// player screen and the lock-screen player.
class PlayerTrackInfo extends StatelessWidget {
  const PlayerTrackInfo({required this.song, super.key});

  final Song song;

  @override
  Widget build(BuildContext context) {
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
            style: AppTypography.playerTitle.copyWith(color: colors.textHigh),
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
