import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_tab.dart';

import 'telegram_controller_test.dart' show settle;
import 'telegram_fakes.dart';

class _NetworkRepository extends FakeTelegramRepository {
  final chatRequests = <Completer<List<TelegramChat>>>[];
  final audioRequests = <Completer<TelegramAudioPage>>[];
  bool restoreOnRetry = false;

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

  @override
  Future<void> retryConnection() async {
    retryConnectionCalls++;
    if (restoreOnRetry) connectionEvents.add(TelegramConnection.ready);
    await pendingConnectionRetry?.future;
  }

  @override
  Future<void> dispose() async {
    for (final pending in chatRequests) {
      if (!pending.isCompleted) pending.complete([]);
    }
    for (final pending in audioRequests) {
      if (!pending.isCompleted) {
        pending.complete(const TelegramAudioPage([], 0));
      }
    }
    if (pendingConnectionRetry != null &&
        !pendingConnectionRetry!.isCompleted) {
      pendingConnectionRetry!.complete();
    }
    await super.dispose();
  }
}

class _NetworkTransport extends TdlibTransport {
  final events = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final commands = <(String, Map<String, dynamic>)>[];
  final stalledCleanup = Completer<Map<String, dynamic>>();
  final cleanupStarted = Completer<void>();
  final stalledBrowse = Completer<Map<String, dynamic>>();
  bool stallBrowse = false;
  final canceled = <String>[];

  @override
  Stream<Map<String, dynamic>> get updates => events.stream;

  @override
  Future<Map<String, dynamic>> call(
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async {
    commands.add((type, fields));
    if (type == 'deleteFile') {
      if (!cleanupStarted.isCompleted) cleanupStarted.complete();
      return stalledCleanup.future;
    }
    return {'@type': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> read(
    String scope,
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async {
    if (stallBrowse && type == 'searchChatMessages') {
      return stalledBrowse.future;
    }
    return call(type, fields);
  }

  @override
  void cancelReads(String scope) => canceled.add(scope);

  void connection(String type) => events.add({
    '@type': 'updateConnectionState',
    'state': {'@type': type},
  });

  @override
  Future<void> dispose() async {
    if (!stalledCleanup.isCompleted) stalledCleanup.complete({'@type': 'ok'});
    if (!stalledBrowse.isCompleted) {
      stalledBrowse.complete({'messages': [], 'next_from_message_id': 0});
    }
    await events.close();
    await super.dispose();
  }
}

const cachedChat = TelegramChat(
  id: 1,
  title: 'Cached',
  kind: 'chatTypePrivate',
);
const freshChat = TelegramChat(id: 2, title: 'Fresh', kind: 'chatTypePrivate');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(_NetworkRepository, ProviderContainer)> setup() async {
    final repository = _NetworkRepository()
      ..savedChats = [cachedChat]
      ..savedAudio = [testAudio(messageId: 1)];
    final container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(FakeTelegramLocalFiles()),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });
    container.read(telegramProvider);
    final subscription = container.listen(telegramChatProvider(123), (_, _) {});
    addTearDown(subscription.close);
    await settle();
    return (repository, container);
  }

  test(
    'real connection recovery refreshes both open lists without another auth-ready event',
    () async {
      final (repository, container) = await setup();
      repository.connectionEvents.add(TelegramConnection.ready);
      repository.events.add(TelegramAuth.ready);
      await settle();
      expect(repository.chatRequests, hasLength(1));
      expect(repository.audioRequests, hasLength(1));
      repository.connectionEvents.add(TelegramConnection.waitingForNetwork);
      await settle();
      expect(container.read(telegramProvider).busy, isFalse);
      expect(container.read(telegramChatProvider(123)).busy, isFalse);
      expect(container.read(telegramProvider).chats.single.id, cachedChat.id);
      repository.connectionEvents.add(TelegramConnection.ready);
      await settle();
      expect(repository.chatRequests, hasLength(2));
      expect(repository.audioRequests, hasLength(2));
      repository.chatRequests.last.complete([freshChat]);
      repository.audioRequests.last.complete(
        TelegramAudioPage([testAudio(messageId: 10)], 0),
      );
      await settle();
      repository.chatRequests.first.completeError(
        const TelegramException(TelegramFailure.network),
      );
      repository.audioRequests.first.completeError(
        const TelegramException(TelegramFailure.network),
      );
      await settle();
      expect(container.read(telegramProvider).chats.single.id, freshChat.id);
      expect(container.read(telegramProvider).busy, isFalse);
      expect(container.read(telegramChatProvider(123)).busy, isFalse);
      expect(container.read(telegramChatProvider(123)).failure, isNull);
      expect(repository.retryConnectionCalls, 0);
      repository.connectionEvents.add(TelegramConnection.ready);
      await settle();
      expect(repository.chatRequests, hasLength(2));
      expect(repository.audioRequests, hasLength(2));
    },
  );

  test(
    'manual refresh recovers TDLib even though authorization is still ready',
    () async {
      final (repository, container) = await setup();
      repository.connectionEvents.add(TelegramConnection.waitingForNetwork);
      repository.events.add(TelegramAuth.ready);
      await settle();
      expect(container.read(telegramProvider).busy, isFalse);
      expect(repository.chatRequests, isEmpty);
      repository.restoreOnRetry = true;
      await container.read(telegramProvider.notifier).refresh();
      await settle();
      expect(repository.retryConnectionCalls, 1);
      expect(repository.chatRequests, hasLength(1));
      expect(repository.audioRequests, hasLength(1));
      repository.chatRequests.single.complete([freshChat]);
      repository.audioRequests.single.complete(const TelegramAudioPage([], 0));
      await settle();
      expect(container.read(telegramProvider).busy, isFalse);
      expect(container.read(telegramProvider).failure, isNull);
      expect(repository.logoutCalls, 0);
    },
  );

  testWidgets(
    'the pull-to-refresh indicator releases after reconnect while old requests are still pending',
    (tester) async {
      final repository = _NetworkRepository()..savedChats = [cachedChat];
      final container = ProviderContainer(
        overrides: [
          telegramRepositoryProvider.overrideWithValue(repository),
          telegramLocalFilesProvider.overrideWithValue(
            FakeTelegramLocalFiles(),
          ),
          allSongsProvider.overrideWithValue([]),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });
      container.read(telegramProvider);
      repository.connectionEvents.add(TelegramConnection.ready);
      repository.events.add(TelegramAuth.ready);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: TelegramTab()),
          ),
        ),
      );
      await tester.pump();
      expect(repository.chatRequests, hasLength(1));
      final refreshing = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(repository.chatRequests, hasLength(2));
      repository.connectionEvents.add(TelegramConnection.waitingForNetwork);
      await tester.pump();
      repository.connectionEvents.add(TelegramConnection.ready);
      await tester.pump();
      expect(repository.chatRequests, hasLength(3));
      repository.chatRequests.last.complete([freshChat]);
      await tester.pumpAndSettle();
      await refreshing;
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(repository.chatRequests[0].isCompleted, isFalse);
      expect(repository.chatRequests[1].isCompleted, isFalse);
      expect(container.read(telegramProvider).chats.single.id, freshChat.id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'superseding a refresh releases its UI future before the obsolete request returns',
    () async {
      final (repository, container) = await setup();
      repository.connectionEvents.add(TelegramConnection.ready);
      repository.events.add(TelegramAuth.ready);
      await settle();
      var oldRootFinished = false;
      var oldAudioFinished = false;
      final root = container
          .read(telegramProvider.notifier)
          .refresh()
          .then((_) => oldRootFinished = true);
      final audio = container
          .read(telegramChatProvider(123).notifier)
          .refresh()
          .then((_) => oldAudioFinished = true);
      await settle();
      repository.connectionEvents.add(TelegramConnection.waitingForNetwork);
      await settle();
      expect(oldRootFinished, isTrue);
      expect(oldAudioFinished, isTrue);
      expect(repository.chatRequests.last.isCompleted, isFalse);
      expect(repository.audioRequests.last.isCompleted, isFalse);
      await root;
      await audio;
    },
  );

  test(
    'pull-to-refresh in a chat invokes connection recovery and ends loading if still offline',
    () async {
      final (repository, container) = await setup();
      repository.connectionEvents.add(TelegramConnection.waitingForNetwork);
      repository.events.add(TelegramAuth.ready);
      await settle();
      await container.read(telegramChatProvider(123).notifier).refresh();
      expect(repository.retryConnectionCalls, 1);
      expect(container.read(telegramChatProvider(123)).busy, isFalse);
      expect(
        container.read(telegramChatProvider(123)).failure,
        TelegramFailure.network,
      );
      expect(repository.audioRequests, isEmpty);
    },
  );

  test(
    'TDLib network retry resets the network in order and coalesces repeated retry taps',
    () async {
      final transport = _NetworkTransport();
      final repository = TelegramRepositoryImpl(
        transportFactory: () => transport,
      );
      addTearDown(repository.dispose);
      final states = <TelegramConnection>[];
      final subscription = repository.connection.listen(states.add);
      addTearDown(subscription.cancel);
      transport.connection('connectionStateWaitingForNetwork');
      await settle();
      await repository.retryConnection();
      await repository.retryConnection();
      final resets = transport.commands
          .where((command) => command.$1 == 'setNetworkType')
          .toList();
      expect(resets.map((command) => (command.$2['type'] as Map)['@type']), [
        'networkTypeNone',
        'networkTypeOther',
      ]);
      expect(states, [TelegramConnection.waitingForNetwork]);
      expect(
        transport.commands.any(
          (command) => command.$1 == 'logOut' || command.$1 == 'deleteFile',
        ),
        isFalse,
      );
    },
  );

  test(
    'connection loss invalidates repository reads so late replies cannot repopulate stale cache',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'telegram-network-cache-',
      );
      final transport = _NetworkTransport()..stallBrowse = true;
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        transportFactory: () => transport,
      );
      addTearDown(() async {
        await repository.dispose();
        await dir.delete(recursive: true);
      });
      final pending = repository.audio(123);
      final rejected = expectLater(pending, throwsA(isA<TelegramException>()));
      transport.connection('connectionStateWaitingForNetwork');
      await settle();
      expect(transport.canceled, contains('audio:123'));
      transport.stalledBrowse.complete({
        'messages': [],
        'next_from_message_id': 0,
      });
      await rejected;
      expect(await repository.cachedAudio(123), isEmpty);
    },
  );

  test(
    'stalled optional cleanup cannot block authorization-ready or list requests',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = await Directory.systemTemp.createTemp(
        'telegram-ready-maintenance-',
      );
      await File('${dir.path}/library-v1.json').writeAsString(
        jsonEncode({
          'temporaryAudio': {'110': testAudio().toJson()},
        }),
      );
      final transport = _NetworkTransport();
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        transportFactory: () => transport,
      );
      addTearDown(() async {
        await repository.dispose();
        await dir.delete(recursive: true);
      });
      final states = <TelegramAuth>[];
      final subscription = repository.authorization.listen(states.add);
      addTearDown(subscription.cancel);
      transport.events.add({
        '@type': 'updateAuthorizationState',
        'authorization_state': {'@type': 'authorizationStateReady'},
      });
      await transport.cleanupStarted.future.timeout(const Duration(seconds: 5));
      await settle();
      expect(states, contains(TelegramAuth.ready));
      expect(
        transport.commands.any((command) => command.$1 == 'deleteFile'),
        isTrue,
      );
      expect(transport.stalledCleanup.isCompleted, isFalse);
      expect(await repository.chats(), isEmpty);
    },
  );
}
