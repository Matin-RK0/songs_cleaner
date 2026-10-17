import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_l10n.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../library/application/providers/library_controller.dart';
import '../../library/domain/entities/song.dart';
import '../application/cleanup_service.dart';
import '../../trash/application/trash_service.dart';

/// Deletes the file immediately and reports the outcome. Shared by the player
/// screen and the library long-press menu.
Future<void> deleteSongFlow(
  BuildContext context,
  WidgetRef ref,
  Song song, {
  bool useTrash = true,
}) async {
  final l10n = context.l10n;
  final result = await ref
      .read(cleanupServiceProvider)
      .deleteFromDevice(song, useTrash: useTrash);
  if (!context.mounted) return;

  switch (result) {
    case CleanupSuccess(:final entry):
      if (!useTrash || entry == null) {
        showAppSnackBar(context, l10n.songDeletedToast(song.title));
        return;
      }
      showAppUndoSnackBar(
        context,
        l10n.songDeletedToast(song.title),
        actionLabel: l10n.undoAction,
        onUndo: () async {
          try {
            await ref.read(trashServiceProvider).restore(entry);
            await ref.read(libraryProvider.notifier).refresh();
          } catch (_) {
            if (context.mounted) {
              showAppSnackBar(context, l10n.trashRestoreFailed, error: true);
            }
          }
        },
      );
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
