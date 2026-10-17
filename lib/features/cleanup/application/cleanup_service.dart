import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/providers/library_controller.dart';
import '../../library/domain/entities/song.dart';
import '../../player/application/providers/player_controller.dart';
import '../../trash/application/trash_service.dart';
import '../../trash/domain/entities/trash_entry.dart';
import '../infrastructure/song_file_deleter.dart';

final cleanupServiceProvider = Provider<CleanupService>(
  (ref) => CleanupService(ref),
);

sealed class CleanupResult {
  const CleanupResult();
}

final class CleanupSuccess extends CleanupResult {
  const CleanupSuccess(this.song, this.entry);

  final Song song;
  final TrashEntry? entry;
}

/// "All files access" was not granted yet; UI should guide to settings.
final class CleanupPermissionMissing extends CleanupResult {
  const CleanupPermissionMissing();
}

final class CleanupFailed extends CleanupResult {
  const CleanupFailed(this.error);

  final Object error;
}

/// Orchestrates deleting a song's file, keeping the play queue and the
/// library consistent, and continuing playback with the next song.
class CleanupService {
  CleanupService(this._ref);

  final Ref _ref;

  Future<CleanupResult> deleteFromDevice(
    Song song, {
    bool useTrash = true,
  }) async {
    final permissions = _ref.read(mediaPermissionsProvider);
    if (!await permissions.hasManageFileAccess()) {
      final granted = await permissions.requestManageFileAccess();
      if (!granted) return const CleanupPermissionMissing();
    }

    try {
      final entry = useTrash
          ? await _ref.read(trashServiceProvider).moveToTrash(song)
          : null;
      if (!useTrash) {
        await _ref.read(songFileDeleterProvider).delete(song);
      }
      try {
        await _ref.read(playerProvider.notifier).removeFromQueue(song.id);
      } catch (_) {
        // Playback state is best-effort; the file is already in Trash.
      }
      _ref.read(libraryProvider.notifier).removeSongLocally(song.id);
      return CleanupSuccess(song, entry);
    } catch (error) {
      return CleanupFailed(error);
    }
  }
}
