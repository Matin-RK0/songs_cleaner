import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_chat_local_inventory_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_chat_summary_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';

import 'telegram_fakes.dart';
import 'telegram_local_matcher_test.dart' show localSong;

class _Downloads extends TelegramDownloadController {
  @override
  Map<int, TelegramDownload> build() => {};

  void publish(TelegramDownload job) => state = {job.audio.fileId: job};
}

class _CountingRepository extends FakeTelegramRepository {
  int bindingReads = 0;
  int audioReads = 0;

  @override
  Future<Map<String, String>> loadBindings() {
    bindingReads++;
    return super.loadBindings();
  }

  @override
  Future<List<TelegramAudio>> cachedAudio(int chatId) {
    audioReads++;
    return super.cachedAudio(chatId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _CountingRepository repository;
  late FakeTelegramLocalFiles files;
  late ProviderContainer container;

  setUp(() {
    repository = _CountingRepository();
    files = FakeTelegramLocalFiles();
    container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(files),
        telegramDownloadsProvider.overrideWith(_Downloads.new),
        allSongsProvider.overrideWithValue([
          localSong(path: '/indexed/song.mp3'),
        ]),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  test(
    'cache-only summary counts playable messages from paths and bindings',
    () async {
      repository.savedAudio = [
        testAudio(messageId: 1, localPath: '/indexed/song.mp3'),
        testAudio(messageId: 2, localPath: '/tdlib/song.mp3'),
        testAudio(messageId: 3, localPath: '/gone.mp3'),
        testAudio(messageId: 4),
        testAudio(messageId: 5), // matched automatically to the indexed copy
      ];
      repository.bindings = {
        '123:1': '/indexed/song.mp3', // do not double count
        '123:4': '/bound.mp3',
        '123:6': '/older.mp3', // binding outside the cached audio page
        '123:7': '/gone.mp3',
        '999:1': '/other-chat.mp3',
      };
      files.existing = {
        '/indexed/song.mp3',
        '/tdlib/song.mp3',
        '/bound.mp3',
        '/older.mp3',
        '/other-chat.mp3',
      };
      final subscription = container.listen(
        telegramChatLocalCountProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        6,
      );
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        6,
      );
      expect(repository.bindingReads, 1);
      expect(repository.audioReads, 1);
      expect(repository.audioCalls, 0);
      expect(repository.connectCalls, 0);
      expect(container.exists(telegramChatProvider(123)), isFalse);
    },
  );

  test(
    'unknown cache stays unknown; known remote or deleted audio counts zero',
    () async {
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        isNull,
      );
      repository.savedAudio = [testAudio(localPath: '/deleted.mp3')];
      container.invalidate(telegramChatLocalCountProvider(123));
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        0,
      );
    },
  );

  test(
    'progress keeps cached counts; completed publishing refreshes them',
    () async {
      final audio = testAudio();
      repository.savedAudio = [audio];
      final subscription = container.listen(
        telegramChatLocalCountProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        0,
      );
      final downloads =
          container.read(telegramDownloadsProvider.notifier) as _Downloads;
      for (var received = 1; received <= 10; received++) {
        downloads.publish(
          TelegramDownload(
            audio: audio,
            phase: TelegramDownloadPhase.receiving,
            received: received,
          ),
        );
        expect(
          await container.read(telegramChatLocalCountProvider(123).future),
          0,
        );
      }
      expect(repository.bindingReads, 1);
      expect(repository.audioReads, 1);
      repository.bindings[audio.key] = '/published.mp3';
      files.existing.add('/published.mp3');
      downloads.publish(
        TelegramDownload(
          audio: audio,
          phase: TelegramDownloadPhase.completed,
          path: '/published.mp3',
        ),
      );
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        1,
      );
      expect(repository.bindingReads, 2);
      expect(repository.audioReads, 2);
    },
  );

  test(
    'open-chat inventory is stable across search and active/local filters',
    () async {
      repository.savedAudio = [
        testAudio(messageId: 1, localPath: '/indexed/song.mp3'),
        testAudio(messageId: 2, localPath: '/tdlib/song.mp3'),
        testAudio(messageId: 3),
      ];
      files.existing = {'/indexed/song.mp3', '/tdlib/song.mp3'};
      final subscription = container.listen(
        telegramChatTotalLocalCountProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(container.read(telegramChatTotalLocalCountProvider(123)), 3);
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        3,
      );
      final controller = container.read(telegramChatProvider(123).notifier);
      controller.search('no matching title');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(container.read(telegramChatSongsProvider(123)), isEmpty);
      expect(container.read(telegramChatTotalLocalCountProvider(123)), 3);
      controller.setActiveOnly();
      expect(container.read(telegramChatTotalLocalCountProvider(123)), 3);
      controller.setLocalOnly(false);
      expect(container.read(telegramChatTotalLocalCountProvider(123)), 3);
    },
  );
}
