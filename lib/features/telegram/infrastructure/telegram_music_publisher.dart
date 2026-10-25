import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/telegram_models.dart';

/// Publishes a completed TDLib file through Android's shared audio collection.
class TelegramMusicPublisher {
  static const channel = MethodChannel(
    'com.example.songs_cleaner/telegram_music',
  );

  Future<bool> openTelegramLink(String link, {String? fallbackLink}) async {
    try {
      return await channel.invokeMethod<bool>('openTelegramLink', {
            'link': link,
            'fallbackLink': ?fallbackLink,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> ensureAccess() async {
    try {
      final legacy =
          await channel.invokeMethod<bool>('requiresLegacyPermission') ?? false;
      if (legacy && !await Permission.storage.request().isGranted) {
        throw const TelegramException(TelegramFailure.storage);
      }
    } on PlatformException {
      throw const TelegramException(TelegramFailure.storage);
    }
  }

  Future<String> publish(String sourcePath, TelegramAudio audio) async {
    try {
      final path = await channel.invokeMethod<String>('saveAudio', {
        'sourcePath': sourcePath,
        'fileName': fileName(audio, sourcePath),
        'title': audio.title,
        'artist': audio.artist,
        'durationMs': audio.duration * 1000,
      });
      if (path == null || path.isEmpty) {
        throw const TelegramException(TelegramFailure.storage);
      }
      return path;
    } on PlatformException {
      throw const TelegramException(TelegramFailure.storage);
    }
  }

  static final _separator = RegExp(r'[/\\]');
  static final _unsafe = RegExp(r'[\x00-\x1f<>:"/\\|?*]');
  static const _audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'flac',
    'wav',
    'wma',
    'amr',
    'aiff',
    'aif',
    'webm',
    'mp4',
  };

  static String fileName(TelegramAudio audio, String sourcePath) {
    final original = audio.fileName
        .split(_separator)
        .last
        .replaceAll(_unsafe, '_')
        .trim();
    if (original.isNotEmpty && original != '.' && original != '..') {
      return original;
    }
    final sourceName = sourcePath.split(_separator).last;
    final extension = sourceName.contains('.')
        ? sourceName.split('.').last.toLowerCase()
        : '';
    final safeExtension = _audioExtensions.contains(extension)
        ? extension
        : 'mp3';
    final title = audio.title.replaceAll(_unsafe, '_').trim();
    return '${title.isEmpty || title == '.' || title == '..' ? 'telegram_${audio.fileId}' : title}.$safeExtension';
  }
}
