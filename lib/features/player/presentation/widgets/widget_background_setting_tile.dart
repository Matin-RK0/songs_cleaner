import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_color_picker_sheet.dart';
import '../../application/providers/widget_background_controller.dart';

class WidgetBackgroundSettingTile extends ConsumerWidget {
  const WidgetBackgroundSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final value = ref.watch(widgetBackgroundColorProvider);
    final colors = context.colors;
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(Icons.widgets_outlined, color: colors.primary),
      title: Text(
        l10n.widgetBackgroundTitle,
        style: AppTypography.emphasisTitle.copyWith(color: colors.textHigh),
      ),
      subtitle: Text(
        value == null
            ? l10n.widgetBackgroundDynamic
            : l10n.widgetBackgroundCustom,
        style: AppTypography.songSubtitle.copyWith(color: colors.textMedium),
      ),
      trailing: value == null
          ? Icon(Icons.auto_awesome_outlined, color: colors.textLow)
          : SizedBox.square(
              dimension: AppSpacing.lg,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: Color(value),
                  shape: CircleBorder(side: BorderSide(color: colors.outline)),
                ),
              ),
            ),
      onTap: () {
        final controller = ref.read(widgetBackgroundColorProvider.notifier);
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: colors.surfaceHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
          ),
          builder: (_) => AppColorPickerSheet(
            initialColor: value == null
                ? AppColorTokens.dark.surfaceHigh
                : Color(value),
            title: l10n.widgetBackgroundTitle,
            onSave: (color) => controller.setColor(color.toARGB32()),
            resetLabel: l10n.widgetBackgroundUseDynamic,
            onReset: () => controller.setColor(null),
          ),
        );
      },
    );
  }
}
