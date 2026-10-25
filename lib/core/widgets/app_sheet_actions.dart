import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A stable, full-width action area shared by settings sheets and dialogs.
class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.cancelLabel,
    required this.onCancel,
    this.busy = false,
    this.resetLabel,
    this.onReset,
    this.destructive = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool busy;
  final String? resetLabel;
  final VoidCallback? onReset;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.md);
    final primary = FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.avatarSize),
        padding: AppSpacing.allMd,
        shape: shape,
        backgroundColor: destructive ? colors.danger : null,
        foregroundColor: destructive ? colors.onPrimary : null,
      ),
      onPressed: busy ? null : onPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.progressStroke,
                semanticsLabel: primaryLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(primaryLabel, textAlign: TextAlign.center)),
        ],
      ),
    );
    final cancel = OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.avatarSize),
        padding: AppSpacing.allMd,
        shape: shape,
        foregroundColor: colors.textHigh,
        side: BorderSide(color: colors.outline),
      ),
      onPressed: busy ? null : onCancel,
      child: Text(cancelLabel, textAlign: TextAlign.center),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stacked controls keep long translations and large text readable.
        primary,
        const SizedBox(height: AppSpacing.sm),
        cancel,
        if (resetLabel != null && onReset != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.textMedium,
              minimumSize: const Size.fromHeight(AppSpacing.avatarSize),
              padding: AppSpacing.allMd,
              shape: shape,
            ),
            onPressed: busy ? null : onReset,
            icon: const Icon(Icons.restore_rounded),
            label: Text(resetLabel!, textAlign: TextAlign.center),
          ),
        ],
      ],
    );
  }
}
