import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared presentation for device and Telegram tracks. No storage/playback rules.
class MusicTrackCard extends StatelessWidget {
  const MusicTrackCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.artwork,
    this.trailing,
    this.onLongPress,
    this.isCurrent = false,
    this.selected = false,
    this.progress,
  });
  final String title;
  final Widget subtitle;
  final Widget? artwork;
  final Widget? trailing;
  final Widget? progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isCurrent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Material(
        color: selected
            ? colors.surfaceHigh
            : colors.surface.withValues(alpha: 0),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(
            color: selected
                ? colors.primary.withValues(alpha: 0.35)
                : colors.primary.withValues(alpha: 0),
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.lg,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.trackRowHeight,
                ),
                child: Padding(
                  padding: AppSpacing.hSmVXs,
                  child: Row(
                    children: [
                      ?artwork,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.songTitle.copyWith(
                                color: isCurrent
                                    ? colors.primary
                                    : colors.textHigh,
                              ),
                            ),
                            DefaultTextStyle(
                              style: AppTypography.songSubtitle.copyWith(
                                color: colors.textMedium,
                              ),
                              child: subtitle,
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
              if (progress != null)
                PositionedDirectional(
                  start: AppSpacing.md,
                  end: AppSpacing.md,
                  bottom: 0,
                  child: RepaintBoundary(child: progress!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
