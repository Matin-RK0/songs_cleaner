import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Commands pushed from the native lock-screen controller to Dart.
enum LockScreenEvent {
  /// The keyguard turned on while a song was playing: show the player route.
  showPlayer,

  /// The device was unlocked: leave the lock-screen player route.
  hidePlayer,

  /// A Routine requested playback after the Flutter UI was already running.
  playRequested,
}

/// Bridges the native [LockScreenController] over a [MethodChannel].
///
/// The native side owns the screen-on/keyguard logic and the activity window
/// flags; this service is the typed Dart seam so feature code never touches raw
/// method names. It is a no-op on non-Android platforms.
class LockScreenService {
  LockScreenService() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static const MethodChannel _channel = MethodChannel(
    'com.example.songs_cleaner/lock_screen',
  );

  final StreamController<LockScreenEvent> _events =
      StreamController<LockScreenEvent>.broadcast();

  /// Native-to-Dart commands (player shown/hidden).
  Stream<LockScreenEvent> get events => _events.stream;

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'showPlayer':
        _events.add(LockScreenEvent.showPlayer);
      case 'hidePlayer':
        _events.add(LockScreenEvent.hidePlayer);
      case 'playRequested':
        _events.add(LockScreenEvent.playRequested);
    }
  }

  /// Signals that Dart is listening and returns whether a show is pending
  /// (the screen turned on before the Flutter side finished booting).
  Future<bool> register() async {
    final pending = await _invoke<bool>('register');
    return pending ?? false;
  }

  Future<bool> isSupported() async {
    if (!_isAndroid) return false;
    final supported = await _invoke<bool>('isSupported');
    return supported ?? false;
  }

  Future<bool> hasOverlayPermission() async {
    if (!_isAndroid) return false;
    final granted = await _invoke<bool>('hasOverlayPermission');
    return granted ?? false;
  }

  /// Opens the system "Display over other apps" screen for this package.
  Future<void> requestOverlayPermission() =>
      _invoke<void>('requestOverlayPermission');

  Future<void> setEnabled(bool enabled) => _invoke<void>('setEnabled', enabled);

  /// Mirrors the live playback rule (`hasCurrent && playing`) so the native
  /// side only reacts to the lock screen while music is actually playing.
  Future<void> setPlaybackActive(bool active) =>
      _invoke<void>('setPlaybackActive', active);

  Future<bool> consumePendingShow() async {
    final pending = await _invoke<bool>('consumePendingShow');
    return pending ?? false;
  }

  Future<bool> consumePendingPlay() async {
    final pending = await _invoke<bool>('consumePendingPlay');
    return pending ?? false;
  }

  /// Back pressed on the lock-screen player: drop the window flags and retreat
  /// to the keyguard.
  Future<void> dismiss() => _invoke<void>('dismiss');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _events.close();
  }
}
