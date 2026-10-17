import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class InsightMetricCard extends StatelessWidget {
  const InsightMetricCard({
    super.key,
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.colors.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.colors.primary),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: AppTypography.sectionTitle.copyWith(
                    color: context.colors.textHigh,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
