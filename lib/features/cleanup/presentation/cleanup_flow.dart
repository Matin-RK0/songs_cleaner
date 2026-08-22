import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_l10n.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../library/application/providers/library_controller.dart';
import '../../library/domain/entities/song.dart';
import '../application/cleanup_service.dart';

/// Confirm → delete file → feedback. Shared by the player screen and the
/// library long-press menu.
Future<void> deleteSongFlow(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  final l10n = context.l10n;
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: l10n.deleteConfirmTitle,
    message: l10n.deleteConfirmMessage(song.title),
    confirmLabel: l10n.delete,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;

  final result = await ref.read(cleanupServiceProvider).deleteFromDevice(song);
  if (!context.mounted) return;

  switch (result) {
    case CleanupSuccess():
      showAppSnackBar(context, l10n.songDeletedToast(song.title));
    case CleanupPermissionMissing():
      final openSettings = await showAppConfirmDialog(
        context: context,
        title: l10n.permissionTitle,
        message: l10n.permissionFilesMessage,
        confirmLabel: l10n.openSettings,
        cancelLabel: l10n.cancel,
      );
      if (openSettings && context.mounted) {
        await ref.read(mediaPermissionsProvider).openPermissionSettings();
      }
    case CleanupFailed():
      showAppSnackBar(
        context,
        l10n.songDeleteFailedToast(song.title),
        error: true,
      );
  }
}
