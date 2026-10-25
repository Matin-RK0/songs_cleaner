import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_preferences_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'telegram_fakes.dart';

Future<void> flushPreferences() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeTelegramRepository repository;
  late ProviderContainer container;
  setUp(() {
    repository = FakeTelegramRepository();
    container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        allSongsProvider.overrideWithValue([]),
        telegramLocalFilesProvider.overrideWithValue(FakeTelegramLocalFiles()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  test(
    'pinned and recently opened chats are ordered before the remaining chats',
    () async {
      repository.savedChats = [
        for (var id = 1; id <= 3; id++)
          TelegramChat(id: id, title: 'Chat $id', kind: 'chatTypePrivate'),
      ];
      repository.preferences = {
        'pins': [2],
        'recent': [3],
      };
      container.read(telegramVisibleChatsProvider);
      await flushPreferences();
      expect(container.read(telegramVisibleChatsProvider).map((e) => e.id), [
        2,
        3,
        1,
      ]);
      container.read(telegramPreferencesProvider.notifier).pin(2);
      await flushPreferences();
      expect(container.read(telegramVisibleChatsProvider).first.id, 3);
    },
  );

  test(
    'recent and per-chat preferences have bounded storage and survive writes',
    () async {
      final preferences = container.read(telegramPreferencesProvider.notifier);
      await preferences.ready;
      for (var id = 0; id < 120; id++) {
        preferences.remember(id);
        preferences.updateChat(id, {'offset': id.toDouble(), 'sort': 'oldest'});
      }
      await flushPreferences();
      expect((repository.preferences['recent'] as List), hasLength(8));
      expect(
        repository.preferences.keys.where((e) => e.startsWith('chat:')),
        hasLength(100),
      );
      expect(preferences.chat(119)['offset'], 119.0);
    },
  );

  test(
    'saved filters restore before local metadata is rendered and search is debounced',
    () async {
      repository.preferences = {
        'chat:123': {'localOnly': false, 'query': '', 'sort': 'oldest'},
      };
      repository.savedAudio = [
        testAudio(messageId: 2),
        testAudio(messageId: 1),
      ];
      final subscription = container.listen(
        telegramChatProvider(123),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await flushPreferences();
      expect(
        container
            .read(telegramChatTracksProvider(123))
            .map((e) => e.audio.messageId),
        [1, 2],
      );
      final controller = container.read(telegramChatProvider(123).notifier);
      controller.search('not found');
      expect(container.read(telegramChatTracksProvider(123)), hasLength(2));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(container.read(telegramChatTracksProvider(123)), isEmpty);
      controller.toggleSelection(repository.savedAudio.first.key);
      expect(
        container.read(telegramSelectionDetailsProvider(123)).remoteBytes,
        1024,
      );
      controller.clearSelection();
      expect(
        container.read(telegramSelectionDetailsProvider(123)).remoteCount,
        0,
      );
    },
  );
}
