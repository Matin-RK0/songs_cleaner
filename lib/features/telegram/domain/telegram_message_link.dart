import 'telegram_models.dart';

class TelegramMessageLink {
  const TelegramMessageLink({required this.appUri, this.webUri});
  final Uri appUri;
  final Uri? webUri;

  static const _supergroupOffset = 1000000000000;
  static const _secretChatOffset = 2000000000000;
  static const _serverMessageMultiplier = 1 << 20;
  static const _maxServerMessageId = 0x7fffffff;
  static const _webHosts = {'t.me', 'telegram.me', 'telegram.dog'};

  /// TDLib server message IDs are shifted by 20 bits; external clients need the
  /// original server ID. Local, pending and scheduled IDs must not be converted.
  static TelegramMessageLink? fromAudio(TelegramAudio audio) {
    if (audio.chatId == 0 ||
        audio.messageId <= 0 ||
        audio.messageId % _serverMessageMultiplier != 0) {
      return null;
    }
    final message = audio.messageId ~/ _serverMessageMultiplier;
    if (message > _maxServerMessageId) return null;
    if (audio.chatId > 0) {
      return TelegramMessageLink(
        appUri: Uri(
          scheme: 'tg',
          host: 'openmessage',
          queryParameters: {
            'user_id': '${audio.chatId}',
            'message_id': '$message',
          },
        ),
      );
    }
    final peer = -audio.chatId;
    if (peer < _supergroupOffset) {
      return TelegramMessageLink(
        appUri: Uri(
          scheme: 'tg',
          host: 'openmessage',
          queryParameters: {'chat_id': '$peer', 'message_id': '$message'},
        ),
      );
    }
    if (peer >= _secretChatOffset || peer == _supergroupOffset) return null;
    final channel = peer - _supergroupOffset;
    return TelegramMessageLink(
      appUri: Uri(
        scheme: 'tg',
        host: 'privatepost',
        queryParameters: {
          'channel': '$channel',
          'post': '$message',
          'single': '',
        },
      ),
      webUri: Uri.https('t.me', '/c/$channel/$message', {'single': ''}),
    );
  }

  /// Preserve thread/comment/media parameters from TDLib's canonical link.
  static TelegramMessageLink? fromHttps(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null ||
        uri.scheme != 'https' ||
        !_webHosts.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return null;
    }
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    final private = parts.isNotEmpty && parts.first == 'c';
    final offset = private ? 1 : 0;
    if (parts.length != offset + 2 && parts.length != offset + 3) return null;
    final post = int.tryParse(parts.last);
    if (post == null || post <= 0) return null;
    final peer = parts[offset];
    if (private && (int.tryParse(peer) ?? 0) <= 0) return null;
    final parameters = {
      ...uri.queryParameters,
      private ? 'channel' : 'domain': peer,
      'post': '$post',
      if (parts.length == offset + 3) 'thread': parts[offset + 1],
    };
    return TelegramMessageLink(
      appUri: Uri(
        scheme: 'tg',
        host: private ? 'privatepost' : 'resolve',
        queryParameters: parameters,
      ),
      webUri: uri,
    );
  }
}
