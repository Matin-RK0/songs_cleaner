import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_audio_mapper.dart';
import 'telegram_fakes.dart';

void main() {
  Map<String, dynamic> file(int id, String path, bool complete) => {
    'id': id,
    'size': 1024,
    'local': {'path': path, 'is_downloading_completed': complete},
  };
  Map<String, dynamic> message({bool complete = true}) => {
    'id': 10,
    'date': 123,
    'content': {
      '@type': 'messageAudio',
      'audio': {
        'title': 'Song',
        'file_name': 'song.mp3',
        'performer': 'Artist',
        'duration': 120,
        'audio': file(11, '/music/song.mp3', complete),
        'album_cover_thumbnail': {'file': file(12, '/covers/song.jpg', true)},
        'album_cover_minithumbnail': {'data': 'YWJj'},
      },
    },
  };

  test('maps a completed download and both Telegram cover formats', () {
    final audio = TelegramAudioMapper.fromMessage(message(), 123)!;
    expect(audio.localPath, '/music/song.mp3');
    expect(audio.coverFileId, 12);
    expect(audio.coverPath, '/covers/song.jpg');
    expect(audio.miniCover, 'YWJj');
    final restored = TelegramAudio.fromJson(audio.toJson());
    expect(restored.coverFileId, audio.coverFileId);
    expect(restored.coverPath, audio.coverPath);
    expect(restored.miniCover, audio.miniCover);
  });
  test('a partial download is not marked locally playable', () {
    expect(
      TelegramAudioMapper.fromMessage(message(complete: false), 123)!.localPath,
      isEmpty,
    );
  });
  test('old cached audio without cover fields remains readable', () {
    final json = testAudio().toJson()
      ..remove('coverFileId')
      ..remove('coverPath')
      ..remove('miniCover');
    final restored = TelegramAudio.fromJson(json);
    expect(restored.coverFileId, 0);
    expect(restored.coverPath, isEmpty);
    expect(restored.miniCover, isEmpty);
  });
  test('non-audio messages are ignored', () {
    expect(
      TelegramAudioMapper.fromMessage({
        'content': {'@type': 'messageText'},
      }, 123),
      isNull,
    );
  });
}
