import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_local_matcher.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'telegram_fakes.dart';

Song localSong({
  String path = '/Telegram/Telegram Audio/song.mp3',
  int size = 1024,
  int id = 1,
}) => Song(
  id: id,
  title: 'Local',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: const Duration(minutes: 2),
  path: path,
  sizeBytes: size,
  dateAddedSeconds: 0,
);

void main() {
  test(
    'same filename and size only suggest a local file, never auto-assign it',
    () {
      final song = localSong();
      final track = TelegramLocalMatcher([song]).resolve(testAudio(), {}, {});
      expect(track.song, isNull);
      expect(track.candidates, [song]);
    },
  );
  test('different size cannot be suggested despite same filename', () {
    final track = TelegramLocalMatcher([
      localSong(size: 1),
    ]).resolve(testAudio(), {}, {});
    expect(track.candidates, isEmpty);
  });
  test(
    'a confirmed existing path resolves to the original MediaStore song',
    () {
      final song = localSong();
      final audio = testAudio();
      final track = TelegramLocalMatcher([
        song,
      ]).resolve(audio, {audio.key: song.path}, {song.path});
      expect(track.song, same(song));
    },
  );
  test('deleted confirmed paths are not presented as available offline', () {
    final audio = testAudio();
    final track = TelegramLocalMatcher(
      [],
    ).resolve(audio, {audio.key: '/gone.mp3'}, {});
    expect(track.song, isNull);
  });
  test('TDLib completed local paths produce playable app-owned songs', () {
    final audio = testAudio(localPath: '/app/song.mp3');
    final track = TelegramLocalMatcher(
      [],
    ).resolve(audio, {}, {'/app/song.mp3'});
    expect(track.song!.path, '/app/song.mp3');
    expect(track.song!.id, isNegative);
    expect(track.song!.duration, const Duration(minutes: 2));
  });
  test('a binding is scoped to its chat/message, even for identical files', () {
    final first = testAudio(chatId: 1);
    final second = testAudio(chatId: 2);
    final matcher = TelegramLocalMatcher([]);
    final bindings = {first.key: '/app/song.mp3'};
    expect(matcher.resolve(first, bindings, {'/app/song.mp3'}).song, isNotNull);
    expect(matcher.resolve(second, bindings, {'/app/song.mp3'}).song, isNull);
  });
  test(
    'Telegram-folder detection uses path segments rather than substrings',
    () {
      expect(
        TelegramLocalMatcher.isTelegramPath(
          '/storage/Android/media/org.telegram.messenger/Telegram/song.mp3',
        ),
        isTrue,
      );
      expect(
        TelegramLocalMatcher.isTelegramPath(
          '/storage/Music/my telegram song.mp3',
        ),
        isFalse,
      );
    },
  );
  test(
    'offline audio metadata survives JSON round-trip with large message ids',
    () {
      final audio = testAudio(
        messageId: 9007199254740000,
        chatId: -1001234567890,
      );
      final restored = TelegramAudio.fromJson(audio.toJson());
      expect(restored.key, audio.key);
      expect(restored.fileId, audio.fileId);
    },
  );
}
