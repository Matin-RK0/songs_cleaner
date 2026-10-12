import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native playback started while the app was closed, offered back to the
/// Flutter player so it can resume the exact track and position.
class NativePlaybackHandoff {
  const NativePlaybackHandoff({required this.path, required this.positionMs});

  final String path;
  final int positionMs;

  Duration get position => Duration(milliseconds: positionMs);
}

/// Controls the native MediaSession used for Samsung Modes and Routines.
class RoutinePlaybackService {
  const RoutinePlaybackService._();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/routine_playback',
  );

  static Future<void> arm() => _invoke('arm');

  static Future<void> disarm() => _invoke('disarm');

  /// Finishes the Android task so the app fully closes instead of staying in
  /// recents. The native handler also stops the routine foreground service and
  /// suppresses its automatic re-arm.
  static Future<void> closeApp() => _invoke('closeApp');

  /// Adopts playback that Samsung Modes and Routines started natively while the
  /// app was closed. Returns the live position and stops the native source, or
  /// null when nothing was playing natively.
  static Future<NativePlaybackHandoff?> handoff() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final result = await _channel.invokeMethod<Object>('handoff');
      if (result is! Map) return null;
      final path = result['path'];
      final positionMs = result['positionMs'];
      if (path is! String || path.isEmpty) return null;
      return NativePlaybackHandoff(
        path: path,
        positionMs: positionMs is int ? positionMs : 0,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> _invoke(String method) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // A background-only Flutter engine has no Activity to move.
    } on MissingPluginException {
      // audio_service can start Flutter without an Activity.
    }
  }
}
