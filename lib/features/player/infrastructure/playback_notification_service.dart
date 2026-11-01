import 'dart:io';

import 'package:flutter/services.dart';

abstract final class PlaybackNotificationService {
  static const channel = MethodChannel('songs_cleaner/playback_notification');

  static Future<void> dismiss() async {
    if (!Platform.isAndroid) return;
    await channel.invokeMethod<void>('dismiss');
  }
}
