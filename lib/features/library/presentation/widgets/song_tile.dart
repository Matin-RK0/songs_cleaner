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
        color: isCurrent ? AppColors.surfaceHigh : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress:
              onDeleteDevice == null ? null : () => _showActions(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showArtwork)
                  ArtworkImage(
                    songId: song.id,
                    size: 52,
                    borderRadius: AppRadius.sm,
                  )
                else
                  const SizedBox(width: AppSpacing.sm),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textHigh,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist.isEmpty
                            ? l10n.unknownArtist
                            : song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  song.duration.mmss,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLow,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
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
