import '../domain/telegram_models.dart';

/// TDLib download state and artwork must survive caching and old cache versions.
abstract final class TelegramAudioMapper {
  static TelegramAudio? fromMessage(Map<String, dynamic> message, int chatId) {
    final content = message['content'] as Map<String, dynamic>;
    if (content['@type'] != 'messageAudio') return null;
    final audio = content['audio'] as Map<String, dynamic>;
    final file = audio['audio'] as Map<String, dynamic>;
    final cover = (audio['album_cover_thumbnail'] as Map?)?['file'] as Map?;
    return TelegramAudio(
      messageId: message['id'] as int,
      chatId: chatId,
      fileId: file['id'] as int,
      fileName: audio['file_name'] as String? ?? '',
      size: file['size'] as int? ?? 0,
      title: audio['title'] as String? ?? '',
      artist: audio['performer'] as String? ?? '',
      duration: audio['duration'] as int? ?? 0,
      date: message['date'] as int? ?? 0,
      localPath: completedPath(file),
      coverFileId: cover?['id'] as int? ?? 0,
      coverPath: cover == null ? '' : completedPath(cover),
      miniCover:
          (audio['album_cover_minithumbnail'] as Map?)?['data'] as String? ??
          '',
    );
  }

  static String completedPath(Map file) {
    final local = file['local'] as Map?;
    return local?['is_downloading_completed'] == true
        ? (local?['path'] as String? ?? '')
        : '';
  }
}
