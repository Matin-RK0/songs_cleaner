import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Central place for every runtime permission the app needs.
class MediaPermissionsService {
  Future<bool> hasAudioAccess() async {
    if (kIsWeb) return true;
    final audio = await Permission.audio.status;
    if (audio.isGranted) return true;
    final storage = await Permission.storage.status;
    return storage.isGranted;
  }

  /// The media notification is silently dropped on Android 13+ until
  /// POST_NOTIFICATIONS is granted, so we ask on every startup until it is
  /// resolved. Permanently-denied users are sent to settings by the caller.
  Future<void> ensureNotificationPermission() async {
    if (kIsWeb) return;
    var status = await Permission.notification.status;
    if (status.isGranted) return;
    if (!status.isPermanentlyDenied) {
      status = await Permission.notification.request();
    }
  }

  /// Requests read access to the device audio library.
  /// Returns the granted status after asking.
  Future<bool> requestAudioAccess() async {
    final granted = await _requestMediaReadAccess();

    // Awaited so both dialogs sequence cleanly instead of racing.
    if (granted) await ensureNotificationPermission();
    return granted;
  }

  Future<bool> _requestMediaReadAccess() async {
    if (await hasAudioAccess()) return true;

    // Android 13+ maps this to READ_MEDIA_AUDIO; older devices fall back
    // to READ_EXTERNAL_STORAGE inside the plugin.
    var status = await Permission.audio.request();
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.storage.request();
    }
    return status.isGranted || status.isLimited;
  }

  Future<bool> hasManageFileAccess() async {
    if (kIsWeb) return true;
    return Permission.manageExternalStorage.status.isGranted;
  }

  /// "All files access" is granted from a system settings page, so after
  /// requesting we re-check the current status (the user may come back later).
  Future<bool> requestManageFileAccess() async {
    if (await hasManageFileAccess()) return true;
    await Permission.manageExternalStorage.request();
    return hasManageFileAccess();
  }

  Future<bool> openPermissionSettings() => openAppSettings();
}
