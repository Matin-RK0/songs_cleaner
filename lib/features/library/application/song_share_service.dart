import 'package:flutter/services.dart';

import '../domain/entities/song.dart';

class SongShareService {
  const SongShareService();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/file_transfer',
  );

  Future<bool> share(Song song) async {
    return await _channel.invokeMethod<bool>('shareSong', {
          'songId': song.id,
          'title': song.title,
        }) ??
        false;
  }
}
