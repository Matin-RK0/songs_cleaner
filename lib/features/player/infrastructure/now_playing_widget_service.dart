import 'package:flutter/services.dart';

class NowPlayingWidgetService {
  const NowPlayingWidgetService();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/now_playing_widget',
  );

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
}
