import 'package:material_ui/material_ui.dart';
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
  // Deleting advances the queue and may unmount the initiating row/button.
  // The route's Scaffold survives both track changes and an empty queue.
  final feedbackContext = Scaffold.maybeOf(context)?.context ?? context;
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await ref
      .read(cleanupServiceProvider)
      .deleteFromDevice(song, useTrash: useTrash);
  if (!feedbackContext.mounted) return;

  switch (result) {
    case CleanupSuccess(:final entry):
      if (!useTrash || entry == null) {
        showAppSnackBar(feedbackContext, l10n.songDeletedToast(song.title));
        return;
      }
      showAppUndoSnackBar(
        feedbackContext,
        l10n.songDeletedToast(song.title),
        actionLabel: l10n.undoAction,
        onUndo: () async {
          try {
            await container.read(trashServiceProvider).restore(entry);
            await container.read(libraryProvider.notifier).refresh();
          } catch (_) {
            if (feedbackContext.mounted) {
              showAppSnackBar(
                feedbackContext,
                l10n.trashRestoreFailed,
                error: true,
              );
            }
          }
        },
      );
    case CleanupPermissionMissing():
      final openSettings = await showAppConfirmDialog(
        context: feedbackContext,
        title: l10n.permissionTitle,
        message: l10n.permissionFilesMessage,
        confirmLabel: l10n.openSettings,
        cancelLabel: l10n.cancel,
      );
      if (openSettings && feedbackContext.mounted) {
        await container.read(mediaPermissionsProvider).openPermissionSettings();
      }
    case CleanupFailed():
      showAppSnackBar(
        feedbackContext,
        l10n.songDeleteFailedToast(song.title),
        error: true,
      );
  }
}
