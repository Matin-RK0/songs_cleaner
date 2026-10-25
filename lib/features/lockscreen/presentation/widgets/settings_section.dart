import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppTypography.sectionLabel.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lg,
              side: BorderSide(color: colors.outline),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }
}

class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.arrow_forward_ios_rounded,
    size: AppSpacing.md,
    color: context.colors.textLow,
  );
}
