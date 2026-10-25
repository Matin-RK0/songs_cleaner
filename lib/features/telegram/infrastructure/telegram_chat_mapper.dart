import '../domain/telegram_models.dart';
import 'telegram_audio_mapper.dart';

abstract final class TelegramChatMapper {
  static TelegramChat fromJson(Map<String, dynamic> chat) {
    final photo = chat['photo'] as Map?;
    // TDLib's 160px variant is sufficient for a list avatar. Never fetch the
    // large/animated profile photo merely to render a scrolling chat row.
    final small = photo?['small'] as Map?;
    return TelegramChat(
      id: chat['id'] as int,
      title: chat['title'] as String,
      kind: (chat['type'] as Map)['@type'] as String,
      photoFileId: small?['id'] as int? ?? 0,
      photoPath: small == null ? '' : TelegramAudioMapper.completedPath(small),
      miniPhoto: (photo?['minithumbnail'] as Map?)?['data'] as String? ?? '',
    );
  }
}
