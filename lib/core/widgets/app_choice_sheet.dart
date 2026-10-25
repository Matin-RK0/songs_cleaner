import 'package:flutter/material.dart';

import '../extensions/context_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppChoice<T> {
  const AppChoice({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Immediate selection: the checked option reflects the saved preference.
Future<T?> showAppChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<AppChoice<T>> choices,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: context.colors.surfaceHigh,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
  ),
  builder: (context) => SafeArea(
    top: false,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppSpacing.contentMaxWidth,
          maxHeight:
              MediaQuery.sizeOf(context).height * AppSpacing.sheetHeightFactor,
        ),
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.sheetTitle.copyWith(
                      color: context.colors.textHigh,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: RadioGroup<T>(
                    groupValue: current,
                    onChanged: (value) => Navigator.of(context).pop(value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final choice in choices)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: RadioListTile<T>(
                              value: choice.value,
                              selected: choice.value == current,
                              activeColor: context.colors.primary,
                              selectedTileColor: context.colors.primary
                                  .withValues(alpha: 0.1),
                              tileColor: context.colors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md,
                                side: BorderSide(
                                  color: choice.value == current
                                      ? context.colors.primary
                                      : context.colors.outline,
                                ),
                              ),
                              contentPadding: AppSpacing.hMdVSm,
                              title: Text(choice.label),
                              secondary: choice.icon == null
                                  ? null
                                  : Icon(choice.icon),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.avatarSize),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
