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
import '../../../../core/widgets/app_color_picker_sheet.dart';
import '../../../../core/widgets/app_choice_sheet.dart';
import '../../../../core/widgets/app_sheet_actions.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../app/router/route_names.dart';
import '../../../player/application/providers/player_preferences_controller.dart';
import '../../../player/application/providers/audio_focus_controller.dart';
import '../../../player/domain/audio_focus_mode.dart';
import '../../../library/presentation/widgets/home_tabs_setting_tile.dart';
import '../../../player/presentation/widgets/widget_background_setting_tile.dart';
import '../../../telegram/presentation/widgets/telegram_cache_controls.dart';
import '../../application/providers/lock_screen_controller.dart';
import '../widgets/settings_section.dart';

/// App settings. Exposes appearance, lock-screen and playback toggles.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _showLockScreenTimeoutSheet(int current) async {
    final l10n = context.l10n;
    final selected = await showAppChoiceSheet<int>(
      context: context,
      title: l10n.lockScreenTimeoutTitle,
      current: current,
      choices: [
        for (final seconds in AppSettingsRepository.lockScreenTimeoutOptions)
          AppChoice(
            value: seconds,
            label: l10n.lockScreenTimeoutSeconds(seconds),
            icon: Icons.timer_outlined,
          ),
      ],
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentMaxWidth,
              ),
              child: Padding(
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
                    Icon(
                      Icons.layers_rounded,
                      size: AppSpacing.xl,
                      color: colors.primary,
                    ),
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
                      style: AppTypography.body.copyWith(
                        color: colors.textMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSheetActions(
                      primaryLabel: l10n.lockScreenPermissionAllow,
                      onPrimary: () => Navigator.of(sheetContext).pop(true),
                      cancelLabel: l10n.lockScreenPermissionNotNow,
                      onCancel: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _showThemeSheet() async {
    final l10n = context.l10n;
    final current = ref.read(appThemeModeProvider);

    final selected = await showAppChoiceSheet<ThemeMode>(
      context: context,
      title: l10n.themeModeTitle,
      current: current,
      choices: [
        for (final mode in ThemeMode.values)
          AppChoice(
            value: mode,
            label: _themeModeLabel(l10n, mode),
            icon: _themeModeIcon(mode),
          ),
      ],
    );

    if (selected != null) {
      await ref.read(appThemeModeProvider.notifier).setMode(selected);
    }
  }

  Future<void> _showPrimaryColorSheet() async {
    final l10n = context.l10n;
    final current = ref.read(appPrimaryColorProvider);
    final primaryController = ref.read(appPrimaryColorProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      builder: (_) => AppColorPickerSheet(
        initialColor: current,
        title: l10n.primaryColorTitle,
        onSave: primaryController.setColor,
      ),
    );
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

    final selected = await showAppChoiceSheet<_LanguageChoice>(
      context: context,
      title: l10n.languageTitle,
      current: current,
      choices: [
        for (final choice in _LanguageChoice.values)
          AppChoice(
            value: choice,
            label: _languageLabel(l10n, choice),
            icon: Icons.translate_rounded,
          ),
      ],
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
    final selected = await showAppChoiceSheet<AudioFocusMode>(
      context: context,
      title: context.l10n.audioFocusTitle,
      current: current,
      choices: [
        for (final mode in AudioFocusMode.values)
          AppChoice(
            value: mode,
            label: _audioFocusLabel(context.l10n, mode),
            icon: Icons.hearing_rounded,
          ),
      ],
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
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: ListTileTheme(
              data: ListTileThemeData(
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                iconColor: colors.primary,
                textColor: colors.textHigh,
                titleTextStyle: AppTypography.emphasisTitle.copyWith(
                  color: colors.textHigh,
                ),
                subtitleTextStyle: AppTypography.songSubtitle.copyWith(
                  color: colors.textMedium,
                ),
              ),
              child: Material(
                color: colors.background,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    SettingsSection(
                      title: l10n.settingsAppearanceSection,
                      children: [
                        ListTile(
                          leading: Icon(
                            _themeModeIcon(themeMode),
                            color: colors.primary,
                          ),
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
                          trailing: const SettingsChevron(),
                          onTap: _showThemeSheet,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.palette_outlined,
                            color: colors.primary,
                          ),
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
                            radius: AppSpacing.lg / 2,
                            backgroundColor: ref.watch(appPrimaryColorProvider),
                          ),
                          onTap: _showPrimaryColorSheet,
                        ),
                        const WidgetBackgroundSettingTile(),
                        const HomeTabsSettingTile(),
                      ],
                    ),
                    SettingsSection(
                      title: l10n.settingsLanguageSection,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.translate_rounded,
                            color: colors.primary,
                          ),
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
                          trailing: const SettingsChevron(),
                          onTap: _showLanguageSheet,
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: l10n.settingsLockScreenSection,
                      children: [
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
                                  l10n.lockScreenTimeoutSeconds(
                                    state.timeoutSeconds,
                                  ),
                                ),
                                trailing: const SettingsChevron(),
                                onTap: state.enabled
                                    ? () => _showLockScreenTimeoutSheet(
                                        state.timeoutSeconds,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: l10n.settingsPlaybackSection,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.hearing_rounded,
                            color: colors.primary,
                          ),
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
                          trailing: const SettingsChevron(),
                          onTap: _showAudioFocusSheet,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.history_rounded,
                            color: colors.primary,
                          ),
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
                          trailing: const SettingsChevron(),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(RouteNames.history),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.delete_sweep_outlined,
                            color: colors.primary,
                          ),
                          title: Text(l10n.trashTitle),
                          subtitle: Text(l10n.trashSettingsSubtitle),
                          trailing: const SettingsChevron(),
                          onTap: () =>
                              Navigator.of(context).pushNamed(RouteNames.trash),
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
                    SettingsSection(
                      title: l10n.telegramTitle,
                      children: [const TelegramCacheTile()],
                    ),
                  ],
                ),
              ),
            ),
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

/// Language choices shown in Settings. `system` follows the device locale.
enum _LanguageChoice { system, english, persian }
