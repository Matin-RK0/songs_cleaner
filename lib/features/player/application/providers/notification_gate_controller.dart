import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_controller.dart';
import '../../../library/infrastructure/media_permissions_service.dart';

/// Lifecycle of the media-notification permission gate.
enum NotificationGateStatus {
  /// Result not resolved yet; UI shows nothing.
  checking,

  granted,

  /// User denied once (or never asked); a system dialog can still appear.
  denied,

  /// Android will never show the dialog again; only settings can fix it.
  permanentlyDenied,

  /// The user closed the in-app banner for this session.
  dismissed,
}

/// Tracks POST_NOTIFICATIONS so the media notification never fails silently:
/// when it is missing, the home screen offers a direct path to grant it.
final notificationGateProvider =
    AsyncNotifierProvider<NotificationGateController, NotificationGateStatus>(
  NotificationGateController.new,
);

class NotificationGateController
    extends AsyncNotifier<NotificationGateStatus> {
  @override
  Future<NotificationGateStatus> build() async {
    // The first request rides along with the audio-permission flow inside
    // MediaPermissionsService.requestAudioAccess(); here we only observe.
    final permissions = ref.watch(mediaPermissionsProvider);
    final status = await _currentStatus(permissions);
    return status;
  }

  static Future<NotificationGateStatus> _currentStatus(
    MediaPermissionsService permissions,
  ) async {
    if (await permissions.hasNotificationAccess()) {
      return NotificationGateStatus.granted;
    }
    final permanentlyDenied =
        await permissions.isNotificationPermanentlyDenied();
    return permanentlyDenied
        ? NotificationGateStatus.permanentlyDenied
        : NotificationGateStatus.denied;
  }

  /// Asks the system for the permission and reflects the outcome.
  Future<void> request() async {
    final permissions = ref.read(mediaPermissionsProvider);
    await permissions.ensureNotificationPermission();
    await recheck();
  }

  /// Re-checks the current status.
  Future<void> recheck() async {
    final permissions = ref.read(mediaPermissionsProvider);
    state = AsyncData(await _currentStatus(permissions));
  }

  /// Sends the user to the app settings page (the only path after a
  /// permanent denial) and re-evaluates when they come back.
  Future<void> resolveViaSettings() async {
    final permissions = ref.read(mediaPermissionsProvider);
    await permissions.openPermissionSettings();
    await recheck();
  }

  void dismiss() {
    state = const AsyncData(NotificationGateStatus.dismissed);
  }
}
