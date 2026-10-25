import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';

import 'telegram_controller_test.dart' show settle;
import 'telegram_fakes.dart';

// Keep controllable requests local to the recovery regressions.
class _PendingRepository extends FakeTelegramRepository {
  final chatRequests = <Completer<List<TelegramChat>>>[];
  final audioRequests = <Completer<TelegramAudioPage>>[];
  final connections = <Completer<void>>[];

  @override
  Future<void> connect() {
    events.add(TelegramAuth.starting);
    final pending = Completer<void>();
    connections.add(pending);
    return pending.future;
  }

  @override
  Future<List<TelegramChat>> chats({bool more = false}) {
    final pending = Completer<List<TelegramChat>>();
    chatRequests.add(pending);
    return pending.future;
  }

  @override
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0}) {
    final pending = Completer<TelegramAudioPage>();
    audioRequests.add(pending);
    return pending.future;
  }
}

const _cached = TelegramChat(id: 1, title: 'Cached', kind: 'private');
const _fresh = TelegramChat(id: 2, title: 'Fresh', kind: 'private');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PendingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _PendingRepository()..savedChats = [_cached];
    container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(FakeTelegramLocalFiles()),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    container.read(telegramProvider);
  });
  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  for (final failOld in [false, true]) {
    test(
      'refresh recovers while offline list request is pending; stale ${failOld ? 'failure' : 'success'} is ignored',
      () async {
        await settle();
        repository.events.add(TelegramAuth.ready);
        expect(repository.chatRequests, hasLength(1));
        final controller = container.read(telegramProvider.notifier);
        final recovery = controller.refresh();
        expect(repository.chatRequests, hasLength(2));
        expect(container.read(telegramProvider).chats.single.id, _cached.id);
        // The old finally block must not end the latest request's busy state.
        if (failOld) {
          repository.chatRequests.first.completeError(
            const TelegramException(TelegramFailure.network),
          );
        } else {
          repository.chatRequests.first.complete([_cached]);
        }
        await settle();
        expect(container.read(telegramProvider).busy, isTrue);
        expect(container.read(telegramProvider).failure, isNull);
        repository.chatRequests.last.complete([_fresh]);
        await recovery;
        await settle();
        expect(container.read(telegramProvider).chats.single.id, _fresh.id);
        expect(container.read(telegramProvider).busy, isFalse);
        expect(repository.chatRequests, hasLength(2));
      },
    );

    test(
      'audio refresh supersedes pending page and ignores late ${failOld ? 'failure' : 'success'}',
      () async {
        repository.savedAudio = [testAudio(messageId: 1)];
        await settle();
        final subscription = container.listen(
          telegramChatProvider(123),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await settle();
        repository.events.add(TelegramAuth.ready);
        await settle();
        expect(repository.audioRequests, hasLength(1));
        final controller = container.read(telegramChatProvider(123).notifier);
        await controller.refresh(more: true);
        expect(repository.audioRequests, hasLength(1));
        final recovery = controller.refresh();
        expect(repository.audioRequests, hasLength(2));
        repository.audioRequests.last.complete(
          TelegramAudioPage([testAudio(messageId: 10)], 9),
        );
        await recovery;
        if (failOld) {
          repository.audioRequests.first.completeError(
            const TelegramException(TelegramFailure.network),
          );
        } else {
          repository.audioRequests.first.complete(
            TelegramAudioPage([testAudio(messageId: 99)], 98),
          );
        }
        await settle();
        final state = container.read(telegramChatProvider(123));
        expect(state.tracks.map((track) => track.audio.messageId), [10, 1]);
        expect(state.nextId, 9);
        expect(state.failure, isNull);
        expect(state.busy, isFalse);
        expect(repository.audioRequests, hasLength(2));
        repository.chatRequests.single.complete([_fresh]);
      },
    );
  }

  test(
    'connecting can be retried explicitly and ready schedules only one refresh',
    () async {
      await settle();
      final controller = container.read(telegramProvider.notifier);
      final old = controller.connect();
      final retry = controller.refresh();
      expect(repository.connections, hasLength(2));
      repository.events.add(TelegramAuth.ready);
      repository.events.add(TelegramAuth.ready);
      repository.connections.last.complete();
      await retry;
      expect(repository.chatRequests, hasLength(1));
      repository.chatRequests.single.complete([_fresh]);
      repository.connections.first.completeError(
        const TelegramException(TelegramFailure.network),
      );
      await old;
      await settle();
      expect(container.read(telegramProvider).failure, isNull);
      expect(container.read(telegramProvider).busy, isFalse);
      expect(repository.chatRequests, hasLength(1));
    },
  );

  testWidgets(
    'bounded list load preserves cache and ignores completion after timeout',
    (tester) async {
      container.dispose();
      await repository.dispose();
      repository = _PendingRepository()..savedChats = [_cached];
      container = ProviderContainer(
        overrides: [telegramRepositoryProvider.overrideWithValue(repository)],
      );
      container.read(telegramProvider);
      await tester.pump();
      repository.events.add(TelegramAuth.ready);
      await tester.pump(const Duration(seconds: 21));
      expect(container.read(telegramProvider).busy, isFalse);
      expect(container.read(telegramProvider).failure, TelegramFailure.network);
      expect(container.read(telegramProvider).chats.single.id, _cached.id);
      repository.chatRequests.single.complete([_fresh]);
      await tester.pump();
      expect(container.read(telegramProvider).chats.single.id, _cached.id);
      expect(repository.chatRequests, hasLength(1));
    },
  );
}
