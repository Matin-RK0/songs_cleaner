import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../library/domain/entities/song.dart';

/// Full-width destructive action that deletes the current song from the device.
/// Shared by the player screen and the lock-screen player.
class DeleteCurrentButton extends ConsumerWidget {
  const DeleteCurrentButton({super.key, required this.song});

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
              fontFamily: AppTypography.fontFamily,
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
