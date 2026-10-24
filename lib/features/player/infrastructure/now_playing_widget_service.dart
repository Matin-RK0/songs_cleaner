import 'package:flutter/services.dart';

class NowPlayingWidgetService {
  const NowPlayingWidgetService();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/now_playing_widget',
  );

  Future<void> setBackgroundColor(int? color) =>
      _channel.invokeMethod<void>('setBackgroundColor', {'color': color});

  Future<void> update({
    String? title,
    String? artist,
    int? songId,
    bool playing = false,
  }) async {
    await _channel.invokeMethod<void>('update', {
      'title': title ?? 'Songs Cleaner',
      'artist': artist ?? 'No song playing',
      'songId': songId,
      'playing': playing,
    });
  }

  Future<String?> consumeAction() =>
      _channel.invokeMethod<String>('consumeAction');

  Future<void> listenToActions(
    Future<void> Function(String action) onAction,
  ) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetAction' && call.arguments is String) {
        await onAction(call.arguments as String);
      }
    });
  }

  void disposeActionListener() {
    _channel.setMethodCallHandler(null);
  }
}
