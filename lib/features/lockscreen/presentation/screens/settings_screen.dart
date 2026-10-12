import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../application/providers/lock_screen_controller.dart';

/// App settings. Currently exposes the lock-screen music controls toggle.
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
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceHigh,
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
            const Icon(
              Icons.layers_rounded,
              size: 34,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.lockScreenPermissionTitle,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textHigh,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.lockScreenPermissionMessage,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 1.6,
                color: AppColors.textMedium,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stateAsync = ref.watch(lockScreenControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppErrorState(title: l10n.errorLoadFailedTitle),
        data: (state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _SectionHeader(title: l10n.settingsLockScreenSection),
            SwitchListTile(
              value: state.enabled,
              onChanged: state.supported
                  ? (value) => _onToggle(state, value)
                  : null,
              title: Text(
                l10n.lockScreenControlTitle,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHigh,
                ),
              ),
              subtitle: Text(
                _subtitle(l10n, state),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textMedium,
                ),
              ),
              secondary: Icon(
                Icons.music_note_rounded,
                color: state.enabled ? AppColors.primary : AppColors.textLow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, LockScreenState state) {
    if (!state.supported) return l10n.lockScreenUnsupportedSubtitle;
    if (!state.overlayGranted) return l10n.lockScreenPermissionNeeded;
    return l10n.lockScreenControlSubtitle;
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
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
