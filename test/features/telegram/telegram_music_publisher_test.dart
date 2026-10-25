import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_music_publisher.dart';

TelegramAudio audioNamed(String name, {String title = ''}) => TelegramAudio(
  messageId: 1,
  chatId: 2,
  fileId: 3,
  fileName: name,
  size: 100,
  title: title,
  artist: 'Artist',
  duration: 120,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(
      TelegramMusicPublisher.channel,
      null,
    ),
  );

  test('keeps original audio filename instead of the TDLib numeric name', () {
    expect(
      TelegramMusicPublisher.fileName(
        audioNamed('My Song.m4a'),
        '/cache/123_456.m4a',
      ),
      'My Song.m4a',
    );
  });
  test('strips path traversal and invalid filename characters', () {
    expect(
      TelegramMusicPublisher.fileName(
        audioNamed('../../My:Song?.mp3'),
        '/cache/a.mp3',
      ),
      'My_Song_.mp3',
    );
  });
  test(
    'missing filename falls back to title and the downloaded audio extension',
    () {
      expect(
        TelegramMusicPublisher.fileName(
          audioNamed('', title: 'آهنگ من'),
          '/cache/123.flac',
        ),
        'آهنگ من.flac',
      );
      expect(
        TelegramMusicPublisher.fileName(audioNamed(''), '/cache/no-extension'),
        'telegram_3.mp3',
      );
    },
  );
  test(
    'uses native shared-storage publishing and returns the public path',
    () async {
      MethodCall? save;
      messenger.setMockMethodCallHandler(TelegramMusicPublisher.channel, (
        call,
      ) async {
        if (call.method == 'requiresLegacyPermission') return false;
        save = call;
        return '/storage/emulated/0/Music/Telegram/Song.mp3';
      });
      final publisher = TelegramMusicPublisher();
      await publisher.ensureAccess();
      final path = await publisher.publish(
        '/private/123.mp3',
        audioNamed('Song.mp3', title: 'Song'),
      );
      expect(path, '/storage/emulated/0/Music/Telegram/Song.mp3');
      expect(save!.method, 'saveAudio');
      expect(save!.arguments, {
        'sourcePath': '/private/123.mp3',
        'fileName': 'Song.mp3',
        'title': 'Song',
        'artist': 'Artist',
        'durationMs': 120000,
      });
    },
  );
  test('storage failures become actionable Telegram failures', () async {
    messenger.setMockMethodCallHandler(
      TelegramMusicPublisher.channel,
      (_) async => throw PlatformException(code: 'SAVE_AUDIO_FAILED'),
    );
    await expectLater(
      TelegramMusicPublisher().publish('/private/a.mp3', audioNamed('a.mp3')),
      throwsA(
        isA<TelegramException>().having(
          (e) => e.failure,
          'failure',
          TelegramFailure.storage,
        ),
      ),
    );
  });
  test(
    'an empty native response is not treated as a successful download',
    () async {
      messenger.setMockMethodCallHandler(
        TelegramMusicPublisher.channel,
        (_) async => null,
      );
      await expectLater(
        TelegramMusicPublisher().publish('/private/a.mp3', audioNamed('a.mp3')),
        throwsA(isA<TelegramException>()),
      );
    },
  );
}
