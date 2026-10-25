import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'telegram_fakes.dart';
import 'telegram_local_matcher_test.dart' show localSong;

Future<void> settle() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeTelegramRepository repository;
  late FakeTelegramLocalFiles files;
  late ProviderContainer container;
  setUp(() {
    repository = FakeTelegramRepository();
    files = FakeTelegramLocalFiles();
    container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(files),
        allSongsProvider.overrideWithValue([]),
        telegramLibrarySyncProvider.overrideWithValue(() async {}),
      ],
    );
    container.read(telegramProvider);
  });
  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  test(
    'existing local music is playable automatically without binding or download',
    () async {
      final song = localSong();
      container.dispose();
      container = ProviderContainer(
        overrides: [
          telegramRepositoryProvider.overrideWithValue(repository),
          telegramLocalFilesProvider.overrideWithValue(files),
          allSongsProvider.overrideWithValue([song]),
        ],
      );
      repository.savedAudio = [testAudio()];
      files.existing.add(song.path);
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      final tracks = container.read(telegramChatTracksProvider(123));
      expect(tracks, hasLength(1));
      expect(tracks.single.song, same(song));
      expect(container.read(telegramChatSongsProvider(123)), [song]);
      expect(repository.bindings, isEmpty);
      expect(repository.downloadCalls, 0);
      expect(repository.audioCalls, 0);
    },
  );

  test('completed native download appears without a manual refresh', () async {
    final audio = testAudio();
    repository.savedAudio = [audio];
    final subscription = container.listen(telegramChatProvider(123), (_, _) {});
    addTearDown(subscription.close);
    await settle();
    expect(container.read(telegramChatTracksProvider(123)), isEmpty);
    files.existing.add('/app/completed.mp3');
    repository.files.add(TelegramLocalFile(audio.fileId, '/app/completed.mp3'));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await settle();
    expect(
      container.read(telegramChatSongsProvider(123)).single.path,
      '/app/completed.mp3',
    );
    expect(repository.audioCalls, 0);
  });

  test('native removal of a missing file clears its local status', () async {
    final audio = testAudio(localPath: '/app/completed.mp3');
    repository.savedAudio = [audio];
    files.existing.add(audio.localPath);
    final subscription = container.listen(telegramChatProvider(123), (_, _) {});
    addTearDown(subscription.close);
    await settle();
    expect(container.read(telegramChatSongsProvider(123)), hasLength(1));
    files.existing.clear();
    repository.files.add(TelegramLocalFile(audio.fileId, ''));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await settle();
    expect(container.read(telegramChatTracksProvider(123)), isEmpty);
  });

  test(
    'a failed public save is not shown as a completed local download',
    () async {
      final audio = testAudio();
      repository.savedAudio = [audio];
      repository.pendingDownload = Completer<void>();
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      final download = container.read(telegramChatProvider(123).notifier);
      repository.events.add(TelegramAuth.ready);
      await settle();
      final waiting = download.download(audio);
      files.existing.add('/private/cache.mp3');
      repository.files.add(
        TelegramLocalFile(audio.fileId, '/private/cache.mp3'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(container.read(telegramChatSongsProvider(123)), isEmpty);
      repository.failure = TelegramFailure.storage;
      repository.pendingDownload!.complete();
      await waiting;
      expect(
        container.read(telegramChatProvider(123)).failure,
        TelegramFailure.storage,
      );
      expect(container.read(telegramChatSongsProvider(123)), isEmpty);
      expect(repository.bindings, isEmpty);
    },
  );

  test(
    'does not start a new Telegram login without an existing session',
    () async {
      await settle();
      expect(repository.connectCalls, 0);
    },
  );
  test('restores a previously authorized session', () async {
    repository.session = true;
    await settle();
    expect(repository.connectCalls, 1);
    expect(container.read(telegramProvider).auth, TelegramAuth.phone);
  });
  test(
    'login moves through phone, code and 2FA and maps code failures',
    () async {
      await settle();
      final controller = container.read(telegramProvider.notifier);
      await controller.connect();
      await controller.submit('+989121234567');
      expect(container.read(telegramProvider).auth, TelegramAuth.code);
      repository.failure = TelegramFailure.code;
      await controller.submit('wrong');
      expect(container.read(telegramProvider).failure, TelegramFailure.code);
      expect(container.read(telegramProvider).busy, isFalse);
      repository.failure = null;
      await controller.submit('12345');
      expect(container.read(telegramProvider).auth, TelegramAuth.password);
    },
  );
  test(
    'cached verified music is available with no account connection',
    () async {
      final audio = testAudio();
      repository.savedAudio = [audio];
      repository.bindings[audio.key] = '/app/song.mp3';
      files.existing.add('/app/song.mp3');
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        '/app/song.mp3',
      );
      expect(repository.audioCalls, 0);
      expect(container.read(telegramChatProvider(123)).busy, isFalse);
    },
  );
  test(
    'pagination deduplicates overlapping pages and preserves older cached music',
    () async {
      repository.savedAudio = [testAudio(messageId: 1)];
      repository.page = TelegramAudioPage([testAudio(messageId: 10)], 9);
      repository.events.add(TelegramAuth.ready);
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      expect(container.read(telegramChatProvider(123)).tracks.length, 2);
      repository.page = TelegramAudioPage([
        testAudio(messageId: 10),
        testAudio(messageId: 9),
      ], 0);
      await container
          .read(telegramChatProvider(123).notifier)
          .refresh(more: true);
      expect(repository.lastFromId, 9);
      expect(
        container
            .read(telegramChatProvider(123))
            .tracks
            .map((e) => e.audio.messageId),
        [10, 9, 1],
      );
    },
  );
  test('network failure retains cached tracks and ends loading', () async {
    repository.savedAudio = [testAudio()];
    repository.failure = TelegramFailure.network;
    repository.events.add(TelegramAuth.ready);
    final subscription = container.listen(telegramChatProvider(123), (_, _) {});
    addTearDown(subscription.close);
    await settle();
    final state = container.read(telegramChatProvider(123));
    expect(state.tracks.length, 1);
    expect(state.busy, isFalse);
    expect(state.failure, TelegramFailure.network);
  });
  test(
    'confirmation binds a device file and unlocks the local playback list',
    () async {
      final audio = testAudio();
      repository.savedAudio = [audio];
      final song = localSong();
      files.existing.add(song.path);
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      await container
          .read(telegramChatProvider(123).notifier)
          .bind(audio, song);
      expect(repository.bindings[audio.key], song.path);
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        song.path,
      );
    },
  );
  test(
    'duplicate download taps share one operation and persist the downloaded path',
    () async {
      final audio = testAudio();
      repository.savedAudio = [audio];
      repository.pendingDownload = Completer<void>();
      files.existing.add(repository.downloadedPath);
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      final controller = container.read(telegramChatProvider(123).notifier);
      repository.events.add(TelegramAuth.ready);
      await settle();
      final downloading = controller.download(audio);
      await controller.download(audio);
      expect(repository.downloadCalls, 1);
      repository.pendingDownload!.complete();
      await downloading;
      expect(repository.bindings[audio.key], repository.downloadedPath);
      expect(container.read(telegramChatProvider(123)).downloading, isEmpty);
      expect(container.read(telegramChatSongsProvider(123)), hasLength(1));
    },
  );
}
