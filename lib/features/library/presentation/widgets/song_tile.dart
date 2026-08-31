import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/entities/song.dart';
import 'artwork_image.dart';

class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isCurrent = false,
    this.showArtwork = true,
    this.onDeleteDevice,
  });

  final Song song;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool showArtwork;
  final ValueChanged<Song>? onDeleteDevice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Material(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress:
              onDeleteDevice == null ? null : () => _showActions(context),
          child: ListTile(
            contentPadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            minVerticalPadding: 0,
            leading: showArtwork
                ? ArtworkImage(
                    songId: song.id,
                    size: 56,
                    borderRadius: AppRadius.lg,
                  )
                : const SizedBox(width: AppSpacing.sm),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: isCurrent ? AppColors.primary : AppColors.textHigh,
              ),
            ),
            subtitle: Text(
              '${song.artist.isEmpty ? l10n.unknownArtist : song.artist}  ·  ${song.duration.mmss}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMedium,
              ),
            ),
            trailing: isCurrent
                ? const Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(l10n.playTooltipShort),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              title: Text(l10n.deleteAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDeleteDevice?.call(song);
              },
            ),
          ],
        ),
      ),
    );
  }
}
