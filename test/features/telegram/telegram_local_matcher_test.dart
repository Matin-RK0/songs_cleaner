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
    'same filename and exact size automatically reuse the indexed local file',
    () {
      final song = localSong();
      final track = TelegramLocalMatcher([
        song,
      ]).resolve(testAudio(), {}, {song.path});
      expect(track.song, same(song));
      expect(track.hasLocalFile, isTrue);
    },
  );
  test('different size cannot match despite same filename', () {
    final song = localSong(size: 1);
    final track = TelegramLocalMatcher([
      song,
    ]).resolve(testAudio(), {}, {song.path});
    expect(track.song, isNull);
  });
  test('different filename does not match based on size alone', () {
    final song = localSong(path: '/Music/another.mp3');
    expect(
      TelegramLocalMatcher([song]).resolve(testAudio(), {}, {song.path}).song,
      isNull,
    );
  });
  test('unknown byte size never automatically matches', () {
    final song = localSong(size: 0);
    expect(
      TelegramLocalMatcher([
        song,
      ]).resolve(testAudio(size: 0), {}, {song.path}).song,
      isNull,
    );
  });
  test('case-insensitive filenames match outside Telegram folders', () {
    final song = localSong(path: '/Music/SONG.MP3');
    expect(
      TelegramLocalMatcher([song]).resolve(testAudio(), {}, {song.path}).song,
      same(song),
    );
  });
  test(
    'duplicate copies resolve stably and skip files which no longer exist',
    () {
      final first = localSong(path: '/Music/a/song.mp3', id: 1);
      final second = localSong(path: '/Music/b/song.mp3', id: 2);
      final paths = {first.path, second.path};
      expect(
        TelegramLocalMatcher([
          second,
          first,
        ]).resolve(testAudio(), {}, paths).song,
        same(first),
      );
      expect(
        TelegramLocalMatcher([
          first,
          second,
        ]).resolve(testAudio(), {}, paths).song,
        same(first),
      );
      expect(
        TelegramLocalMatcher([
          first,
          second,
        ]).resolve(testAudio(), {}, {second.path}).song,
        same(second),
      );
    },
  );
  test('saved bindings take priority over automatic copies', () {
    final first = localSong(path: '/Music/a/song.mp3', id: 1);
    final second = localSong(path: '/Music/b/song.mp3', id: 2);
    final audio = testAudio();
    expect(
      TelegramLocalMatcher([first, second])
          .resolve(audio, {audio.key: second.path}, {first.path, second.path})
          .song,
      same(second),
    );
  });
  test('a missing saved path falls back to an existing local copy', () {
    final song = localSong();
    final audio = testAudio(localPath: '/deleted/native.mp3');
    expect(
      TelegramLocalMatcher([
        song,
      ]).resolve(audio, {audio.key: '/deleted/bound.mp3'}, {song.path}).song,
      same(song),
    );
  });
  test('the same local file can play in multiple chats without a binding', () {
    final song = localSong();
    final matcher = TelegramLocalMatcher([song]);
    for (final id in [1, 2]) {
      expect(
        matcher.resolve(testAudio(chatId: id), {}, {song.path}).song,
        same(song),
      );
    }
  });
  test('missing device files are not counted as local candidates', () {
    final track = TelegramLocalMatcher([
      localSong(),
    ]).resolve(testAudio(), {}, {});
    expect(track.hasLocalFile, isFalse);
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
