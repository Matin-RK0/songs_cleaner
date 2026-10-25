import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_chat_summary_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_cache_controls.dart';

import 'telegram_fakes.dart';

class _ImageTransport extends TdlibTransport {
  final calls = <(String, Map<String, dynamic>)>[];
  Completer<Map<String, dynamic>>? pendingAudio;

  @override
  Future<Map<String, dynamic>> read(
    String scope,
    String type, [
    Map<String, dynamic> fields = const {},
  ]) {
    if (type == 'searchChatMessages' && pendingAudio != null) {
      return pendingAudio!.future;
    }
    return call(type, fields);
  }

  @override
  Future<Map<String, dynamic>> call(
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async {
    calls.add((type, fields));
    return {'@type': 'ok'};
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline cleanup deletes private images and metadata, retaining music, database and queue',
    () async {
      final dir = await Directory.systemTemp.createTemp('telegram-clear-');
      addTearDown(() => dir.delete(recursive: true));
      Future<File> file(String relative) async {
        final file = File('${dir.path}/$relative');
        await file.parent.create(recursive: true);
        return file.writeAsBytes([1, 2, 3]);
      }

      final cover = await file('files/thumbnails/cover.jpg');
      final photo = await file('files/profile_photos/chat.jpg');
      final music = await file('files/music/paused.mp3');
      final public = await file('Music/Telegram/song.mp3');
      final external = await file('files-public/photo.jpg');
      final database = await file('db/td.binlog');
      final audio = testAudio(localPath: public.path);
      final seed = <String, dynamic>{
        'chats': [
          TelegramChat(
            id: 123,
            title: 'Chat',
            kind: 'chatTypePrivate',
            photoPath: photo.path,
          ).toJson(),
        ],
        'audio:123': [audio.toJson()],
        'cover:1': cover.path,
        'cover:2': external.path,
        'cover:3':
            music.path, // an image index must never delete a known audio path
        'files': {'110': public.path},
        'publishedFiles': {'110': public.path},
        'bindings': {audio.key: public.path},
        'temporaryAudio': {'111': testAudio(localPath: music.path).toJson()},
        'transfers': [audio.toJson()],
        'preferences': {
          'parallel': 2,
          'pins': [123],
        },
      };
      await File('${dir.path}/library-v1.json').writeAsString(jsonEncode(seed));
      final repository = TelegramRepositoryImpl(cacheDirectory: dir);
      await repository.clearCache();
      await repository.dispose();
      expect(await cover.exists(), isFalse);
      expect(await photo.exists(), isFalse);
      for (final kept in [music, public, external, database]) {
        expect(await kept.readAsBytes(), [1, 2, 3]);
      }
      final reopened = TelegramRepositoryImpl(cacheDirectory: dir);
      addTearDown(reopened.dispose);
      expect(await reopened.cachedChats(), isEmpty);
      expect(await reopened.cachedAudio(123), isEmpty);
      expect(await reopened.loadBindings(), seed['bindings']);
      expect(await reopened.loadPreferences(), seed['preferences']);
      expect(await reopened.savedTransfers(), hasLength(1));
      final saved =
          jsonDecode(await File('${dir.path}/library-v1.json').readAsString())
              as Map;
      expect(
        saved.keys.any((key) => key.toString().startsWith('cover:')),
        isFalse,
      );
      expect(saved['temporaryAudio'], seed['temporaryAudio']);
      expect(saved['publishedFiles'], seed['publishedFiles']);
      expect(saved['imagePurgePending'], isTrue);
    },
  );

  test(
    'native cache purge explicitly targets images and excludes audio',
    () async {
      final dir = await Directory.systemTemp.createTemp('telegram-images-');
      final transport = _ImageTransport();
      final repository = TelegramRepositoryImpl(
        cacheDirectory: dir,
        transportFactory: () => transport,
      );
      addTearDown(() async {
        await repository.dispose();
        await dir.delete(recursive: true);
      });
      await repository.clearCache();
      final purge = transport.calls
          .singleWhere((call) => call.$1 == 'optimizeStorage')
          .$2;
      expect(purge['file_types'], [
        {'@type': 'fileTypeThumbnail'},
        {'@type': 'fileTypeProfilePhoto'},
      ]);
      expect(purge['size'], 0);
      expect(
        transport.calls.any(
          (call) => call.$1 == 'logOut' || call.$1 == 'deleteFile',
        ),
        isFalse,
      );
    },
  );

  ProviderContainer containerFor(FakeTelegramRepository repository) {
    final container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(
          FakeTelegramLocalFiles()..existing.add('/Music/song.mp3'),
        ),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    return container;
  }

  test(
    'a pending metadata request cannot repopulate the cache after clearing',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'telegram-stale-cache-',
      );
      final transport = _ImageTransport()
        ..pendingAudio = Completer<Map<String, dynamic>>();
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
      await repository.clearCache();
      transport.pendingAudio!.complete({
        '@type': 'foundChatMessages',
        'messages': [],
        'next_from_message_id': 0,
      });
      await rejected;
      final snapshot =
          jsonDecode(await File('${dir.path}/library-v1.json').readAsString())
              as Map;
      expect(snapshot.containsKey('audio:123'), isFalse);
    },
  );

  test(
    'clear updates mounted chats and summaries without logging out or downloading again',
    () async {
      final repository = FakeTelegramRepository()
        ..savedAudio = [testAudio(localPath: '/Music/song.mp3')]
        ..savedChats = [
          const TelegramChat(id: 123, title: 'Chat', kind: 'chatTypePrivate'),
        ];
      final container = containerFor(repository);
      final chat = container.listen(telegramChatProvider(123), (_, _) {});
      final summary = container.listen(
        telegramChatLocalCountProvider(123),
        (_, _) {},
      );
      addTearDown(chat.close);
      addTearDown(summary.close);
      await _settle();
      repository.events.add(TelegramAuth.ready);
      await _settle();
      expect(container.read(telegramChatProvider(123)).tracks, hasLength(1));
      final controller = container.read(telegramProvider.notifier);
      expect(await controller.clearCache(), isTrue);
      expect(container.read(telegramProvider).auth, TelegramAuth.ready);
      expect(container.read(telegramProvider).chats, isEmpty);
      expect(container.read(telegramChatProvider(123)).tracks, isEmpty);
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        isNull,
      );
      expect(repository.logoutCalls, 0);
      expect(repository.downloadCalls, 0);
      expect(container.read(telegramProvider).busy, isFalse);
    },
  );

  test(
    'failed cleanup reports failure and does not clear the visible index',
    () async {
      final repository = FakeTelegramRepository()
        ..failCacheClear = true
        ..savedChats = [
          const TelegramChat(id: 123, title: 'Chat', kind: 'chatTypePrivate'),
        ];
      final container = containerFor(repository);
      final controller = container.read(telegramProvider.notifier);
      await _settle();
      expect(await controller.clearCache(), isFalse);
      expect(container.read(telegramProvider).chats, hasLength(1));
      expect(container.read(telegramProvider).cacheRevision, 0);
      expect(repository.logoutCalls, 0);
      expect(container.read(telegramProvider).failure, TelegramFailure.storage);
    },
  );

  test(
    'duplicate clears share busy protection; sign-out is explicit',
    () async {
      final repository = FakeTelegramRepository()
        ..pendingCacheClear = Completer<void>();
      final container = containerFor(repository);
      final controller = container.read(telegramProvider.notifier);
      await _settle();
      final first = controller.clearCache();
      expect(container.read(telegramProvider).clearingCache, isTrue);
      expect(await controller.clearCache(), isFalse);
      expect(repository.clearCacheCalls, 1);
      repository.pendingCacheClear!.complete();
      expect(await first, isTrue);
      expect(container.read(telegramProvider).clearingCache, isFalse);
      expect(repository.logoutCalls, 0);
      expect(await controller.clearCache(signOut: true), isTrue);
      expect(repository.logoutCalls, 1);
      expect(container.read(telegramProvider).auth, TelegramAuth.disconnected);
    },
  );

  for (final locale in ['en', 'fa']) {
    testWidgets(
      'cache button explains session choice and supports cancel and clear in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeTelegramRepository();
        final container = containerFor(repository);
        container.read(telegramProvider);
        repository.events.add(TelegramAuth.ready);
        await tester.pump();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(child: TelegramCacheTile()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(TelegramCacheTile)),
        );
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(find.text(l10n.telegramClearCacheHint), findsOneWidget);
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isFalse,
        );
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        expect(repository.clearCacheCalls, 0);
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, l10n.telegramClearCache),
        );
        await tester.pumpAndSettle();
        expect(repository.clearCacheCalls, 1);
        expect(repository.logoutCalls, 0);
        expect(find.text(l10n.telegramCacheCleared), findsOneWidget);
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, l10n.telegramClearCache),
        );
        await tester.pumpAndSettle();
        expect(repository.logoutCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
