import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/appearance_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/appearance_controller.dart';
import '../../../../core/theme/system_palette_controller.dart';
import '../../../../core/widgets/app_choice_sheet.dart';
import '../../../../core/widgets/app_color_picker_sheet.dart';
import '../../../../core/widgets/app_feedback.dart';
import 'photo_dimming_sheet.dart';
import 'photo_framing_sheet.dart';

class AppearanceCustomizationTiles extends ConsumerWidget {
  const AppearanceCustomizationTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final supportsSystem = ref.watch(systemPaletteProvider).value != null;
    final systemActive = supportsSystem && appearance.systemTheme;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supportsSystem)
          SwitchListTile(
            secondary: const Icon(Icons.wallpaper_outlined),
            title: Text(l10n.fullSystemThemeTitle),
            subtitle: Text(l10n.fullSystemThemeSubtitle),
            value: systemActive,
            onChanged: (enabled) => _run(
              context,
              () =>
                  ref.read(appearanceProvider.notifier).setSystemTheme(enabled),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(l10n.appBackgroundTitle),
          subtitle: Text(switch (appearance.backgroundKind) {
            AppBackgroundKind.standard => l10n.appearanceDefault,
            AppBackgroundKind.color => l10n.appBackgroundSolid,
            AppBackgroundKind.photo => l10n.appBackgroundPhoto,
          }),
          enabled: !systemActive,
          onTap: () => _chooseBackground(context, ref, appearance),
        ),
        if (appearance.photoPath case final String path)
          ListTile(
            leading: const Icon(Icons.crop_rounded),
            title: Text(l10n.photoFramingTitle),
            enabled: !systemActive,
            onTap: () async {
              final controller = ref.read(appearanceProvider.notifier);
              final framing = await showPhotoFramingSheet(
                context,
                path,
                initial: appearance.photoFraming,
              );
              if (context.mounted && framing != null) {
                await _run(
                  context,
                  () => controller.setPhotoFraming(path, framing),
                );
              }
            },
          ),
        if (appearance.photoPath case final String path)
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.appBackgroundDimming),
            enabled: !systemActive,
            onTap: () async {
              final controller = ref.read(appearanceProvider.notifier);
              final dimming = await showPhotoDimmingSheet(
                context,
                path,
                appearance.photoDimming,
                appearance.photoFraming,
              );
              if (context.mounted && dimming != null) {
                await _run(context, () => controller.setPhotoDimming(dimming));
              }
            },
          ),
        ListTile(
          leading: const Icon(Icons.format_color_text_rounded),
          title: Text(l10n.appForegroundTitle),
          subtitle: Text(l10n.appForegroundSubtitle),
          trailing: CircleAvatar(backgroundColor: context.colors.textHigh),
          enabled: !systemActive,
          onTap: () {
            final controller = ref.read(appearanceProvider.notifier);
            _showColorPicker(
              context,
              l10n.appForegroundTitle,
              appearance.foregroundColor == null
                  ? context.colors.textHigh
                  : Color(appearance.foregroundColor!),
              controller.setForegroundColor,
              onReset: controller.resetForeground,
            );
          },
        ),
      ],
    );
  }

  Future<void> _chooseBackground(
    BuildContext context,
    WidgetRef ref,
    AppearancePreferences appearance,
  ) async {
    final l10n = context.l10n;
    final controller = ref.read(appearanceProvider.notifier);
    final selected = await showAppChoiceSheet<AppBackgroundKind>(
      context: context,
      title: l10n.appBackgroundTitle,
      // Choices are actions as well: tapping Photo again replaces the image.
      current: null,
      choices: [
        AppChoice(
          value: AppBackgroundKind.standard,
          label: l10n.appearanceDefault,
          icon: Icons.restart_alt_rounded,
        ),
        AppChoice(
          value: AppBackgroundKind.color,
          label: l10n.appBackgroundSolid,
          icon: Icons.format_color_fill_outlined,
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          AppChoice(
            value: AppBackgroundKind.photo,
            label: l10n.appBackgroundPhoto,
            icon: Icons.photo_library_outlined,
          ),
      ],
    );
    if (!context.mounted || selected == null) return;
    switch (selected) {
      case AppBackgroundKind.standard:
        await _run(context, controller.resetBackground);
      case AppBackgroundKind.color:
        await _showColorPicker(
          context,
          l10n.appBackgroundSolid,
          appearance.backgroundColor == null
              ? context.colors.background
              : Color(appearance.backgroundColor!),
          controller.setBackgroundColor,
        );
      case AppBackgroundKind.photo:
        await _run(
          context,
          () => controller.pickPhoto(
            (path) async =>
                context.mounted ? showPhotoFramingSheet(context, path) : null,
          ),
        );
    }
  }

  Future<void> _showColorPicker(
    BuildContext context,
    String title,
    Color current,
    Future<void> Function(int) save, {
    Future<void> Function()? onReset,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surfaceHigh,
    builder: (_) => AppColorPickerSheet(
      initialColor: current,
      title: title,
      onSave: (color) => save(color.toARGB32()),
      onReset: onReset,
      resetLabel: context.l10n.appearanceDefault,
    ),
  );

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, context.l10n.actionFailedGeneric, error: true);
      }
    }
  }
}
