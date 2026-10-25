import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_preferences_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_download_activity.dart';
import 'telegram_fakes.dart';

Future<void> drain() async {
  for (var i = 0; i < 25; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class FakeDownloadActivity extends TelegramDownloadActivity {
  final calls = <(int, int)>[];
  @override
  Future<void> update(int active, int queued, {String? languageCode}) async {
    calls.add((active, queued));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeTelegramRepository repository;
  late FakeDownloadActivity activity;
  late ProviderContainer container;
  late TelegramDownloadController manager;
  final played = <String>[];
  var disposed = false;

  setUp(() async {
    disposed = false;
    played.clear();
    repository = FakeTelegramRepository();
    activity = FakeDownloadActivity();
    container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramDownloadActivityProvider.overrideWithValue(activity),
        telegramLibrarySyncProvider.overrideWithValue(() async {}),
        telegramDownloadPlayerProvider.overrideWithValue((song) async {
          played.add(song.path);
        }),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    manager = container.read(telegramDownloadsProvider.notifier);
    await drain();
    repository.events.add(TelegramAuth.ready);
    await drain();
  });
  tearDown(() async {
    if (!disposed) container.dispose();
    for (final gate in repository.transferGates.values) {
      if (!gate.isCompleted) gate.complete();
    }
    await drain();
    await repository.dispose();
  });

  TelegramAudio gated(int message) {
    final audio = testAudio(messageId: message);
    repository.transferGates[audio.fileId] = Completer<void>();
    return audio;
  }

  test(
    'logout waits for an atomic public commit and blocks new transfers until unlocked',
    () async {
      final audio = gated(1);
      manager.enqueue(audio);
      await drain();
      repository.progressCallbacks[audio.fileId]!(
        const TelegramTransferProgress(
          received: 1024,
          total: 1024,
          saving: true,
        ),
      );
      var ready = false;
      final logout = manager.prepareLogout().then((_) {
        ready = true;
      });
      await drain();
      expect(ready, isFalse);
      expect(manager.enqueue(testAudio(messageId: 2)), isFalse);
      repository.transferGates[audio.fileId]!.complete();
      await logout;
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
      expect(repository.bindings[audio.key], repository.downloadedPath);
      manager.unlock();
      expect(manager.enqueue(gated(3)), isTrue);
    },
  );

  test(
    'blocked storage pauses waiting items instead of repeatedly downloading into a full destination',
    () async {
      final first = gated(1), second = gated(2), third = gated(3);
      for (final audio in [first, second, third]) {
        manager.enqueue(audio);
      }
      await drain();
      repository.failure = TelegramFailure.storage;
      repository.transferGates[first.fileId]!.complete();
      await drain();
      expect(repository.downloadCalls, 2);
      expect(
        container.read(telegramDownloadsProvider)[third.fileId]!.phase,
        TelegramDownloadPhase.paused,
      );
      await manager.waitFor(third.fileId);
    },
  );

  test(
    'queue limits concurrent requests and starts the next item after completion',
    () async {
      final first = gated(1), second = gated(2), third = gated(3);
      for (final audio in [first, second, third]) {
        manager.enqueue(audio);
      }
      await drain();
      expect(repository.downloadCalls, 2);
      expect(container.read(telegramDownloadSummaryProvider), (2, 1, 0, 0));
      repository.transferGates[first.fileId]!.complete();
      await drain();
      expect(repository.downloadCalls, 3);
      expect(
        container.read(telegramDownloadsProvider)[third.fileId]!.phase,
        TelegramDownloadPhase.receiving,
      );
    },
  );

  test('same file in different chats shares a single transfer', () async {
    final audio = gated(1);
    manager.enqueue(audio);
    manager.enqueue(testAudio(messageId: 1, chatId: 999));
    await drain();
    expect(repository.downloadCalls, 1);
    expect(container.read(telegramDownloadsProvider), hasLength(1));
  });

  test(
    'byte progress is coalesced and does not rebuild ids or summary subscribers',
    () async {
      final audio = gated(1);
      manager.enqueue(audio);
      await drain();
      var idChanges = 0, summaryChanges = 0;
      final ids = container.listen(telegramDownloadIdsProvider, (_, _) {
        idChanges++;
      });
      final summary = container.listen(telegramDownloadSummaryProvider, (_, _) {
        summaryChanges++;
      });
      addTearDown(ids.close);
      addTearDown(summary.close);
      final callback = repository.progressCallbacks[audio.fileId]!;
      for (var i = 1; i <= 100; i++) {
        callback(TelegramTransferProgress(received: i, total: 1000));
      }
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.received,
        0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final job = container.read(telegramDownloadsProvider)[audio.fileId]!;
      expect(job.received, 100);
      expect(job.fraction, 0.1);
      expect(idChanges, 0);
      expect(summaryChanges, 0);
      callback(const TelegramTransferProgress(received: 500, total: 1000));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.bytesPerSecond,
        greaterThan(0),
      );
    },
  );

  test(
    'saving is a distinct non-cancelable phase until the public file is committed',
    () async {
      final audio = gated(1);
      manager.enqueue(audio);
      await drain();
      repository.progressCallbacks[audio.fileId]!(
        const TelegramTransferProgress(
          received: 1024,
          total: 1024,
          saving: true,
        ),
      );
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.saving,
      );
      await manager.pause(audio.fileId, discard: true);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.saving,
      );
      repository.transferGates[audio.fileId]!.complete();
      await drain();
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
      expect(repository.bindings[audio.key], repository.downloadedPath);
    },
  );

  test(
    'resume waits for native cancellation to settle and ignores stale progress',
    () async {
      final audio = gated(1);
      manager.enqueue(audio);
      await drain();
      final stale = repository.progressCallbacks[audio.fileId]!;
      repository.cancelGate = Completer<void>();
      final stopping = manager.pause(audio.fileId, discard: true);
      await drain();
      repository.transferGates[audio.fileId] = Completer<void>();
      manager.resume(audio.fileId);
      stale(const TelegramTransferProgress(received: 9999, total: 10000));
      await drain();
      expect(repository.downloadCalls, 1);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.received,
        0,
      );
      repository.cancelGate!.complete();
      await stopping;
      await drain();
      expect(repository.downloadCalls, 2);
      repository.transferGates[audio.fileId]!.complete();
      await drain();
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
    },
  );

  test('failure can be retried without duplicating the queue entry', () async {
    final audio = gated(1);
    repository.failure = TelegramFailure.storage;
    manager.enqueue(audio);
    repository.transferGates[audio.fileId]!.complete();
    await drain();
    expect(
      container.read(telegramDownloadsProvider)[audio.fileId]!.failure,
      TelegramFailure.storage,
    );
    repository.failure = null;
    repository.transferGates[audio.fileId] = Completer<void>();
    manager.resume(audio.fileId);
    repository.transferGates[audio.fileId]!.complete();
    await drain();
    expect(container.read(telegramDownloadsProvider), hasLength(1));
    expect(
      container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
      TelegramDownloadPhase.completed,
    );
  });

  test('parallel limit is adjustable and persisted', () async {
    container.read(telegramPreferencesProvider.notifier).parallel(1);
    await drain();
    for (var i = 1; i <= 3; i++) {
      manager.enqueue(gated(i));
    }
    await drain();
    expect(repository.downloadCalls, 1);
    expect(repository.preferences['parallel'], 1);
    container.read(telegramPreferencesProvider.notifier).parallel(3);
    await drain();
    expect(repository.downloadCalls, 3);
  });

  test(
    'downloads outlive a chat provider and play-after-download is explicit',
    () async {
      final audio = gated(1);
      final chat = container.listen(
        telegramChatProvider(audio.chatId),
        (_, _) {},
      );
      await drain();
      manager.enqueue(audio, play: true);
      chat.close();
      await container.pump();
      repository.transferGates[audio.fileId]!.complete();
      await drain();
      expect(played, [repository.downloadedPath]);
      expect(activity.calls.last.$1, 0);
    },
  );

  test(
    'pause all does not start waiting downloads while active slots are released',
    () async {
      for (var i = 1; i <= 4; i++) {
        manager.enqueue(gated(i));
      }
      await drain();
      await manager.pauseAll();
      await drain();
      expect(repository.downloadCalls, 2);
      expect(
        container
            .read(telegramDownloadsProvider)
            .values
            .every((e) => e.phase == TelegramDownloadPhase.paused),
        isTrue,
      );
    },
  );

  test(
    'restored queue is paused with zero claimed bytes until explicitly resumed',
    () async {
      final audio = gated(1);
      repository.transfers = [audio];
      container.invalidate(telegramDownloadsProvider);
      manager = container.read(telegramDownloadsProvider.notifier);
      await drain();
      expect(repository.downloadCalls, 0);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.paused,
      );
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.received,
        0,
      );
      manager.resume(audio.fileId);
      await drain();
      expect(repository.downloadCalls, 1);
    },
  );

  test(
    'disposing during progress stops heartbeat and pending flush without late state writes',
    () async {
      final audio = gated(1);
      manager.enqueue(audio);
      await drain();
      repository.progressCallbacks[audio.fileId]!(
        const TelegramTransferProgress(received: 100, total: 200),
      );
      container.dispose();
      disposed = true;
      repository.transferGates[audio.fileId]!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(activity.calls.last, (0, 0));
    },
  );

  test(
    'unknown totals stay indeterminate and ETA requires a measured speed',
    () {
      final unknown = TelegramDownload(audio: testAudio(), received: 100);
      expect(unknown.fraction, isNull);
      expect(unknown.remainingSeconds, isNull);
      expect(
        unknown.copyWith(total: 200, bytesPerSecond: 25).remainingSeconds,
        4,
      );
      expect(unknown.copyWith(total: 50).fraction, 1);
    },
  );
}
