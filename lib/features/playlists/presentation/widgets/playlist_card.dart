import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Grid card used on the playlists tab: square cover with a title and a small
/// subtitle underneath.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.lg,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: colors.textHigh,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: colors.textMedium,
          ),
        ),
      ],
    );
  }
}
