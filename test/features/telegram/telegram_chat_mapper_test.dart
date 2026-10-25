import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_chat_mapper.dart';

void main() {
  test('maps the small chat photo and preserves it in the offline cache', () {
    final chat = TelegramChatMapper.fromJson({
      'id': 123,
      'title': 'Music',
      'type': {'@type': 'chatTypeSupergroup'},
      'photo': {
        'small': {
          'id': 45,
          'local': {
            'is_downloading_completed': true,
            'path': '/cache/avatar.jpg',
          },
        },
        'big': {'id': 46},
        'minithumbnail': {'data': 'YWJj'},
      },
    });
    expect(chat.photoFileId, 45);
    expect(chat.photoPath, '/cache/avatar.jpg');
    expect(chat.miniPhoto, 'YWJj');
    final cached = TelegramChat.fromJson(chat.toJson());
    expect(cached.photoFileId, chat.photoFileId);
    expect(cached.photoPath, chat.photoPath);
    expect(cached.miniPhoto, chat.miniPhoto);
  });

  test(
    'a pending profile download retains its id but not a partial file path',
    () {
      final chat = TelegramChatMapper.fromJson({
        'id': 1,
        'title': 'Friend',
        'type': {'@type': 'chatTypePrivate'},
        'photo': {
          'small': {
            'id': 99,
            'local': {
              'is_downloading_completed': false,
              'path': '/partial.jpg',
            },
          },
        },
      });
      expect(chat.photoFileId, 99);
      expect(chat.photoPath, isEmpty);
    },
  );

  test('chats without profile photos use a placeholder', () {
    final chat = TelegramChatMapper.fromJson({
      'id': 1,
      'title': 'Friend',
      'type': {'@type': 'chatTypePrivate'},
      'photo': null,
    });
    expect(chat.photoFileId, 0);
    expect(chat.photoPath, isEmpty);
  });

  test('old cached chats without photo fields remain readable', () {
    final chat = TelegramChat.fromJson({
      'id': 1,
      'title': 'Old',
      'kind': 'chatTypePrivate',
    });
    expect(chat.photoFileId, 0);
    expect(chat.miniPhoto, isEmpty);
  });
}
