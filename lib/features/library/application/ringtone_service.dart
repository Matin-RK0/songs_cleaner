import 'package:flutter/services.dart';

import '../domain/entities/song.dart';

class RingtoneService {
  const RingtoneService();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/file_transfer',
  );

  Future<void> setAsRingtone(Song song) {
    return _channel.invokeMethod<void>('setAsRingtone', {
      'songId': song.id,
      'title': song.title,
    });
  }
}
