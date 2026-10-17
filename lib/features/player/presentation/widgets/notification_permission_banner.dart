import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/providers/notification_gate_controller.dart';

/// Compact banner shown while POST_NOTIFICATIONS is missing. Without it the
/// media notification fails silently on Android 13+, and after a permanent
/// denial Android never shows the system dialog again — only settings helps.
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final status =
        ref.watch(notificationGateProvider).value ??
        NotificationGateStatus.checking;

    final needsAction =
        status == NotificationGateStatus.denied ||
        status == NotificationGateStatus.permanentlyDenied;
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: needsAction
          ? _PermissionBanner(
              key: ValueKey(status),
              status: status,
              l10n: l10n,
              colors: colors,
              ref: ref,
            )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    super.key,
    required this.status,
    required this.l10n,
    required this.colors,
    required this.ref,
  });

  final NotificationGateStatus status;
  final AppLocalizations l10n;
  final AppColorTokens colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Material(
      color: colors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 20,
              color: colors.textMedium,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.notifPermissionTitle,
                    style: AppTypography.bannerTitle.copyWith(
                      color: colors.textHigh,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.notifPermissionMessage,
                    style: AppTypography.captionSmall.copyWith(
                      color: colors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final controller = ref.read(notificationGateProvider.notifier);
              if (status == NotificationGateStatus.permanentlyDenied) {
                controller.resolveViaSettings();
              } else {
                controller.request();
              }
            },
            child: Text(
              status == NotificationGateStatus.permanentlyDenied
                  ? l10n.openSettings
                  : l10n.grantPermission,
            ),
          ),
          IconButton(
            tooltip: l10n.closeTooltip,
            onPressed: ref.read(notificationGateProvider.notifier).dismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    ),
  );
}
