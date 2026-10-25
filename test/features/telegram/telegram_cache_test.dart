import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_music_publisher.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'telegram_fakes.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('telegram-cache-test');
  });
  tearDown(() => dir.delete(recursive: true));

  test(
    'concurrent cold-cache reads and bindings retain every downloaded path after restart',
    () async {
      final repository = TelegramRepositoryImpl(cacheDirectory: dir);
      await Future.wait([
        repository.cachedChats(),
        repository.cachedAudio(123),
        repository.bind('123:1', '/app/first.mp3'),
        repository.bind('123:2', '/app/second.mp3'),
      ]);
      await repository.dispose();
      final reopened = TelegramRepositoryImpl(cacheDirectory: dir);
      addTearDown(reopened.dispose);
      expect(await reopened.loadBindings(), {
        '123:1': '/app/first.mp3',
        '123:2': '/app/second.mp3',
      });
    },
  );

  test(
    'cached download index restores the path when message metadata predates completion',
    () async {
      final audio = testAudio();
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'audio:123': [audio.toJson()],
          'files': {'${audio.fileId}': '/app/downloaded.mp3'},
        }),
      );
      final repository = TelegramRepositoryImpl(cacheDirectory: dir);
      addTearDown(repository.dispose);
      expect(
        (await repository.cachedAudio(123)).single.localPath,
        '/app/downloaded.mp3',
      );
    },
  );

  test(
    'publishes cached audio once and restores the public path for every chat after restart',
    () async {
      final audio = testAudio();
      final other = testAudio(chatId: 456);
      final source = await File(
        '${dir.path}/tdlib.mp3',
      ).writeAsBytes([1, 2, 3]);
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'audio:123': [audio.toJson()],
          'audio:456': [other.toJson()],
          'files': {'${audio.fileId}': source.path},
        }),
      );
      final publisher = FakeMusicPublisher(
        '${dir.path}/Music/Telegram/song.mp3',
      );
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        musicPublisher: publisher,
      );
      final results = await Future.wait([
        repository.download(audio),
        repository.download(other),
      ]);
      final published = results.first;
      expect(results.last, published);
      expect(published, publisher.destination);
      expect(await File(published).readAsBytes(), [1, 2, 3]);
      expect(await repository.download(audio), published);
      expect(publisher.publishCalls, 1);
      await repository.dispose();

      final reopened = TelegramRepositoryImpl(
        cacheDirectory: dir,
        musicPublisher: publisher,
      );
      addTearDown(reopened.dispose);
      expect((await reopened.cachedAudio(123)).single.localPath, published);
      expect((await reopened.loadBindings())[other.key], published);
      expect(await reopened.download(audio), published);
      expect(publisher.publishCalls, 1);
    },
  );

  test(
    'failed public save does not record a successful published download',
    () async {
      final audio = testAudio();
      final source = await File(
        '${dir.path}/tdlib.mp3',
      ).writeAsBytes([1, 2, 3]);
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'files': {'${audio.fileId}': source.path},
        }),
      );
      final publisher = FakeMusicPublisher(
        '${dir.path}/Music/Telegram/song.mp3',
      )..fail = true;
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        musicPublisher: publisher,
      );
      addTearDown(repository.dispose);
      await expectLater(
        repository.download(audio),
        throwsA(isA<TelegramException>()),
      );
      final saved =
          jsonDecode(await File('${dir.path}/library-v1.json').readAsString())
              as Map;
      expect(saved['publishedFiles'], isNull);
      expect(await repository.loadBindings(), isEmpty);
    },
  );

  test(
    'only the verified private TDLib copy is removed after successful publication',
    () async {
      final audio = testAudio();
      final source = File('${dir.path}/files/music/private.mp3');
      await source.parent.create(recursive: true);
      await source.writeAsBytes([1, 2, 3]);
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'files': {'${audio.fileId}': source.path},
          'audio:123': [audio.toJson()],
        }),
      );
      final publisher = FakeMusicPublisher(
        '${dir.path}/Music/Telegram/song.mp3',
      );
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        musicPublisher: publisher,
      );
      addTearDown(repository.dispose);
      final path = await repository.download(audio);
      expect(await File(path).readAsBytes(), [1, 2, 3]);
      expect(await source.exists(), isFalse);
      expect((await repository.cachedAudio(123)).single.localPath, path);
    },
  );

  test(
    'cache cleanup cannot delete a public or similarly-prefixed source folder',
    () async {
      final audio = testAudio();
      final source = File('${dir.path}/files-public/original.mp3');
      await source.parent.create(recursive: true);
      await source.writeAsBytes([1, 2, 3]);
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'files': {'${audio.fileId}': source.path},
        }),
      );
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        musicPublisher: FakeMusicPublisher(
          '${dir.path}/Music/Telegram/song.mp3',
        ),
      );
      addTearDown(repository.dispose);
      await repository.download(audio);
      expect(await source.readAsBytes(), [1, 2, 3]);
    },
  );
}

class FakeMusicPublisher extends TelegramMusicPublisher {
  FakeMusicPublisher(this.destination);
  final String destination;
  int publishCalls = 0;
  bool fail = false;
  @override
  Future<void> ensureAccess() async {}
  @override
  Future<String> publish(String sourcePath, TelegramAudio audio) async {
    publishCalls++;
    if (fail) throw const TelegramException(TelegramFailure.storage);
    final file = File(destination);
    await file.parent.create(recursive: true);
    await File(sourcePath).copy(destination);
    return destination;
  }
}
