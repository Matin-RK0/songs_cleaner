import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';

class TelegramSectionHeader extends StatelessWidget {
  const TelegramSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
  });
  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: AppSpacing.lg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.telegramSectionCount(count),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
