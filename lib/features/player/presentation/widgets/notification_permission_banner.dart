import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
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
    final status =
        ref.watch(notificationGateProvider).value ?? NotificationGateStatus.checking;

    final needsAction = status == NotificationGateStatus.denied ||
        status == NotificationGateStatus.permanentlyDenied;
    if (!needsAction) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Material(
        color: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(start: AppSpacing.md),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 20,
                color: AppColors.textMedium,
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
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.notifPermissionMessage,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: AppColors.textMedium,
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
}
