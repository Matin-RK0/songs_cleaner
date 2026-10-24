import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/settings/app_settings_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/primary_color_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../app/router/route_names.dart';
import '../../../player/application/providers/player_preferences_controller.dart';
import '../../../player/application/providers/audio_focus_controller.dart';
import '../../../player/domain/audio_focus_mode.dart';
import '../../application/providers/lock_screen_controller.dart';

/// App settings. Exposes appearance, lock-screen and playback toggles.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _showLockScreenTimeoutSheet(int current) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.lockScreenTimeoutTitle,
                style: AppTypography.sectionTitle,
              ),
            ),
            RadioGroup<int>(
              groupValue: current,
              onChanged: (value) => Navigator.of(sheetContext).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final seconds
                      in AppSettingsRepository.lockScreenTimeoutOptions)
                    RadioListTile<int>(
                      value: seconds,
                      title: Text(l10n.lockScreenTimeoutSeconds(seconds)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await ref
          .read(lockScreenControllerProvider.notifier)
          .setTimeoutSeconds(selected);
    }
  }

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
              style: AppTypography.sheetTitleSmall.copyWith(
                color: colors.textHigh,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.lockScreenPermissionMessage,
              style: AppTypography.body.copyWith(color: colors.textMedium),
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
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.themeModeTitle,
                style: AppTypography.sectionTitle.copyWith(
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

  Future<void> _showPrimaryColorSheet() async {
    final l10n = context.l10n;
    final current = ref.read(appPrimaryColorProvider);

    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.primaryColorTitle,
                style: AppTypography.sectionTitle.copyWith(
                  color: sheetContext.colors.textHigh,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                itemCount: AppPrimaryPalette.colors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                ),
                itemBuilder: (context, index) {
                  final isSelected = index == current;
                  final color = AppPrimaryPalette.colors[index];
                  return Semantics(
                    label: l10n.primaryColorOption(index + 1),
                    selected: isSelected,
                    button: true,
                    child: InkResponse(
                      onTap: () => Navigator.of(sheetContext).pop(index),
                      radius: 30,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: color,
                          shape: CircleBorder(
                            side: isSelected
                                ? BorderSide(
                                    color: sheetContext.colors.textHigh,
                                    width: 3,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await ref.read(appPrimaryColorProvider.notifier).setIndex(selected);
    }
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.themeModeSystem,
        ThemeMode.light => l10n.themeModeLight,
        ThemeMode.dark => l10n.themeModeDark,
      };

  Future<void> _showLanguageSheet() async {
    final l10n = context.l10n;
    final current = _languageChoice(ref.read(appLocaleProvider));

    final selected = await showModalBottomSheet<_LanguageChoice>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.languageTitle,
                style: AppTypography.sectionTitle.copyWith(
                  color: sheetContext.colors.textHigh,
                ),
              ),
            ),
            RadioGroup<_LanguageChoice>(
              groupValue: current,
              onChanged: (value) => Navigator.of(sheetContext).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final choice in _LanguageChoice.values)
                    RadioListTile<_LanguageChoice>(
                      value: choice,
                      activeColor: sheetContext.colors.primary,
                      title: Text(_languageLabel(l10n, choice)),
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
      await ref
          .read(appLocaleProvider.notifier)
          .setLocale(_localeFor(selected));
    }
  }

  _LanguageChoice _languageChoice(Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => _LanguageChoice.english,
        'fa' => _LanguageChoice.persian,
        _ => _LanguageChoice.system,
      };

  Locale? _localeFor(_LanguageChoice choice) => switch (choice) {
    _LanguageChoice.system => null,
    _LanguageChoice.english => const Locale('en'),
    _LanguageChoice.persian => const Locale('fa'),
  };

  Future<void> _showAudioFocusSheet() async {
    final current = ref.read(audioFocusModeProvider);
    final selected = await showModalBottomSheet<AudioFocusMode>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<AudioFocusMode>(
          groupValue: current,
          onChanged: (value) => Navigator.of(sheetContext).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  context.l10n.audioFocusTitle,
                  style: AppTypography.sectionTitle.copyWith(
                    color: context.colors.textHigh,
                  ),
                ),
              ),
              for (final mode in AudioFocusMode.values)
                RadioListTile<AudioFocusMode>(
                  value: mode,
                  title: Text(_audioFocusLabel(context.l10n, mode)),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(audioFocusModeProvider.notifier).setMode(selected);
    }
  }

  String _languageLabel(AppLocalizations l10n, _LanguageChoice choice) =>
      switch (choice) {
        _LanguageChoice.system => l10n.languageSystem,
        _LanguageChoice.english => l10n.languageEnglish,
        _LanguageChoice.persian => l10n.languagePersian,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lockScreenState = ref.watch(lockScreenControllerProvider);
    final previousGoesToPrevious = ref.watch(previousGoesToPreviousProvider);
    final hideQuickDelete = ref.watch(hideQuickDeleteProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final audioFocusMode = ref.watch(audioFocusModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListTileTheme(
        data: ListTileThemeData(
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          tileColor: colors.surfaceHigh.withValues(alpha: 0.22),
        ),
        child: Material(
          color: colors.background,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              _SectionHeader(title: l10n.settingsAppearanceSection),
              ListTile(
                leading: Icon(_themeModeIcon(themeMode), color: colors.primary),
                title: Text(
                  l10n.themeModeTitle,
                  style: AppTypography.emphasisTitle.copyWith(
                    color: colors.textHigh,
                  ),
                ),
                subtitle: Text(
                  _themeModeLabel(l10n, themeMode),
                  style: AppTypography.songSubtitle.copyWith(
                    color: colors.textMedium,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: colors.textLow,
                ),
                onTap: _showThemeSheet,
              ),
              ListTile(
                leading: Icon(Icons.palette_outlined, color: colors.primary),
                title: Text(
                  l10n.primaryColorTitle,
                  style: AppTypography.emphasisTitle.copyWith(
                    color: colors.textHigh,
                  ),
                ),
                subtitle: Text(
                  l10n.primaryColorSubtitle,
                  style: AppTypography.songSubtitle.copyWith(
                    color: colors.textMedium,
                  ),
                ),
                trailing: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppPrimaryPalette
                      .colors[ref.watch(appPrimaryColorProvider)],
                ),
                onTap: _showPrimaryColorSheet,
              ),
              _SectionHeader(title: l10n.settingsLanguageSection),
              ListTile(
                leading: Icon(Icons.translate_rounded, color: colors.primary),
                title: Text(
                  l10n.languageTitle,
                  style: AppTypography.listTitle.copyWith(
                    color: colors.textHigh,
                  ),
                ),
                subtitle: Text(
                  _languageLabel(l10n, _languageChoice(locale)),
                  style: AppTypography.songSubtitle.copyWith(
                    color: colors.textMedium,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: colors.textLow,
                ),
                onTap: _showLanguageSheet,
              ),
              _SectionHeader(title: l10n.settingsLockScreenSection),
              lockScreenState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) =>
                    AppErrorState(title: l10n.errorLoadFailedTitle),
                data: (state) => Column(
                  children: [
                    _SettingSwitchTile(
                      value: state.enabled,
                      onChanged: state.supported
                          ? (value) => _onToggle(state, value)
                          : null,
                      title: l10n.lockScreenControlTitle,
                      subtitle: _subtitle(l10n, state),
                      icon: Icons.music_note_rounded,
                    ),
                    ListTile(
                      enabled: state.enabled,
                      leading: Icon(
                        Icons.timer_outlined,
                        color: colors.primary,
                      ),
                      title: Text(l10n.lockScreenTimeoutTitle),
                      subtitle: Text(
                        l10n.lockScreenTimeoutSeconds(state.timeoutSeconds),
                      ),
                      onTap: state.enabled
                          ? () => _showLockScreenTimeoutSheet(
                              state.timeoutSeconds,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              _SectionHeader(title: l10n.settingsPlaybackSection),
              ListTile(
                leading: Icon(Icons.hearing_rounded, color: colors.primary),
                title: Text(
                  l10n.audioFocusTitle,
                  style: AppTypography.emphasisTitle.copyWith(
                    color: colors.textHigh,
                  ),
                ),
                subtitle: Text(
                  _audioFocusLabel(l10n, audioFocusMode),
                  style: AppTypography.songSubtitle.copyWith(
                    color: colors.textMedium,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: colors.textLow,
                ),
                onTap: _showAudioFocusSheet,
              ),
              ListTile(
                leading: Icon(Icons.history_rounded, color: colors.primary),
                title: Text(
                  l10n.historyTitle,
                  style: AppTypography.emphasisTitle.copyWith(
                    color: colors.textHigh,
                  ),
                ),
                subtitle: Text(
                  l10n.historySettingsSubtitle,
                  style: AppTypography.songSubtitle.copyWith(
                    color: colors.textMedium,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: colors.textLow,
                ),
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteNames.history),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: colors.primary,
                ),
                title: Text(l10n.trashTitle),
                subtitle: Text(l10n.trashSettingsSubtitle),
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: colors.textLow,
                ),
                onTap: () => Navigator.of(context).pushNamed(RouteNames.trash),
              ),
              _SettingSwitchTile(
                value: previousGoesToPrevious,
                onChanged: (value) => ref
                    .read(previousGoesToPreviousProvider.notifier)
                    .setEnabled(value),
                title: l10n.previousGoesToPreviousTitle,
                subtitle: l10n.previousGoesToPreviousSubtitle,
                icon: Icons.skip_previous_rounded,
              ),
              _SettingSwitchTile(
                value: hideQuickDelete,
                onChanged: (value) => ref
                    .read(hideQuickDeleteProvider.notifier)
                    .setEnabled(value),
                title: l10n.hideQuickDeleteTitle,
                subtitle: l10n.hideQuickDeleteSubtitle,
                icon: Icons.delete_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  String _audioFocusLabel(AppLocalizations l10n, AudioFocusMode mode) =>
      switch (mode) {
        AudioFocusMode.pause => l10n.audioFocusPause,
        AudioFocusMode.duck => l10n.audioFocusDuck,
        AudioFocusMode.ignore => l10n.audioFocusIgnore,
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
        style: AppTypography.emphasisTitle.copyWith(color: colors.textHigh),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.songSubtitle.copyWith(color: colors.textMedium),
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
        style: AppTypography.sectionLabel.copyWith(
          color: context.colors.primary,
        ),
      ),
    );
  }
}

/// Language choices shown in Settings. `system` follows the device locale.
enum _LanguageChoice { system, english, persian }
