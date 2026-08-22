import 'dart:async';

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

  /// Requests read access to the device audio library.
  /// Returns the granted status after asking.
  Future<bool> requestAudioAccess() async {
    if (await hasAudioAccess()) return true;

    // Android 13+ maps this to READ_MEDIA_AUDIO; older devices fall back
    // to READ_EXTERNAL_STORAGE inside the plugin.
    var status = await Permission.audio.request();
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.storage.request();
    }
    final granted = status.isGranted || status.isLimited;

    // The media notification needs POST_NOTIFICATIONS on 13+; best effort.
    if (granted) unawaited(Permission.notification.request());
    return granted;
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
