import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_preferences_controller.dart';
import '../../application/providers/lock_screen_controller.dart';

/// App settings. Exposes appearance, lock-screen and playback toggles.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppLifecycleListener? _lifecycleListener;

  /// Set while the user is taken to system settings to grant the overlay
  /// permission, so returning with it granted flips the toggle on.
  bool _pendingEnable = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    final controller = ref.read(lockScreenControllerProvider.notifier);
    await controller.refreshPermission();
    if (!mounted) return;
    final state = ref.read(lockScreenControllerProvider).value;
    if (_pendingEnable && (state?.overlayGranted ?? false)) {
      _pendingEnable = false;
      await controller.setEnabled(true);
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.lockScreenEnabledToast);
    }
  }

  Future<void> _onToggle(LockScreenState state, bool value) async {
    final l10n = context.l10n;
    final controller = ref.read(lockScreenControllerProvider.notifier);

    if (!value) {
      await controller.setEnabled(false);
      if (!mounted) return;
      showAppSnackBar(context, l10n.lockScreenDisabledToast);
      return;
    }

    if (state.overlayGranted) {
      await controller.setEnabled(true);
      if (!mounted) return;
      showAppSnackBar(context, l10n.lockScreenEnabledToast);
      return;
    }

    _pendingEnable = true;
    final allow = await _showPermissionSheet();
    if (allow) {
      await controller.requestOverlayPermission();
    } else {
      _pendingEnable = false;
    }
  }

  Future<bool> _showPermissionSheet() async {
    final l10n = context.l10n;
    final colors = context.colors;
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.layers_rounded, size: 34, color: colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.lockScreenPermissionTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textHigh,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.lockScreenPermissionMessage,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 1.6,
                color: colors.textMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(l10n.lockScreenPermissionNotNow),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text(l10n.lockScreenPermissionAllow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _showThemeSheet() async {
    final l10n = context.l10n;
    final current = ref.read(appThemeModeProvider);

    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.themeModeTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: sheetContext.colors.textHigh,
                ),
              ),
            ),
            RadioGroup<ThemeMode>(
              groupValue: current,
              onChanged: (value) => Navigator.of(sheetContext).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      activeColor: sheetContext.colors.primary,
                      title: Text(_themeModeLabel(l10n, mode)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected != null) {
      await ref.read(appThemeModeProvider.notifier).setMode(selected);
    }
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.themeModeSystem,
        ThemeMode.light => l10n.themeModeLight,
        ThemeMode.dark => l10n.themeModeDark,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lockScreenState = ref.watch(lockScreenControllerProvider);
    final previousGoesToPrevious = ref.watch(previousGoesToPreviousProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader(title: l10n.settingsAppearanceSection),
          ListTile(
            leading: Icon(_themeModeIcon(themeMode), color: colors.primary),
            title: Text(
              l10n.themeModeTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textHigh,
              ),
            ),
            subtitle: Text(
              _themeModeLabel(l10n, themeMode),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                height: 1.4,
                color: colors.textMedium,
              ),
            ),
            trailing: Icon(Icons.chevron_left_rounded, color: colors.textLow),
            onTap: _showThemeSheet,
          ),
          _SectionHeader(title: l10n.settingsLockScreenSection),
          lockScreenState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => AppErrorState(title: l10n.errorLoadFailedTitle),
            data: (state) => _SettingSwitchTile(
              value: state.enabled,
              onChanged: state.supported
                  ? (value) => _onToggle(state, value)
                  : null,
              title: l10n.lockScreenControlTitle,
              subtitle: _subtitle(l10n, state),
              icon: Icons.music_note_rounded,
            ),
          ),
          _SectionHeader(title: l10n.settingsPlaybackSection),
          _SettingSwitchTile(
            value: previousGoesToPrevious,
            onChanged: (value) => ref
                .read(previousGoesToPreviousProvider.notifier)
                .setEnabled(value),
            title: l10n.previousGoesToPreviousTitle,
            subtitle: l10n.previousGoesToPreviousSubtitle,
            icon: Icons.skip_previous_rounded,
          ),
        ],
      ),
    );
  }

  IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  String _subtitle(AppLocalizations l10n, LockScreenState state) {
    if (!state.supported) return l10n.lockScreenUnsupportedSubtitle;
    if (!state.overlayGranted) return l10n.lockScreenPermissionNeeded;
    return l10n.lockScreenControlSubtitle;
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: colors.textHigh,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          height: 1.4,
          color: colors.textMedium,
        ),
      ),
      secondary: Icon(icon, color: value ? colors.primary : colors.textLow),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
