import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_avatar_palette.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_chat_sections_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_sections_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_preferences_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download_group.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/providers/telegram_avatar_identity_provider.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_tab.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_chat_avatar.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_download_sheet.dart';

import 'telegram_fakes.dart';

class _Downloads extends TelegramDownloadController {
  @override
  Map<int, TelegramDownload> build() => {};

  void put(int id, TelegramDownloadPhase phase, {int received = 0}) {
    final audio = TelegramAudio.fromJson({
      ...testAudio(messageId: id).toJson(),
      'fileId': id,
      'title': 'Track $id',
    });
    state = {
      ...state,
      id: TelegramDownload(audio: audio, phase: phase, received: received),
    };
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer(FakeTelegramRepository repository) {
    final container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(FakeTelegramLocalFiles()),
        telegramDownloadsProvider.overrideWith(_Downloads.new),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    return container;
  }

  FakeTelegramRepository chatsRepository() => FakeTelegramRepository()
    ..savedChats = const [
      TelegramChat(id: 1, title: 'Music pinned', kind: 'chatTypePrivate'),
      TelegramChat(id: 2, title: 'Other two', kind: 'chatTypePrivate'),
      TelegramChat(id: 3, title: 'Pinned three', kind: 'chatTypePrivate'),
      TelegramChat(id: 4, title: 'Music other', kind: 'chatTypePrivate'),
    ]
    ..preferences = {
      'pins': [3, 1],
      'recent': [4, 2],
    };

  test(
    'chat sections retain pin/recent order and respond to search and unpin',
    () async {
      final container = createContainer(chatsRepository());
      final subscription = container.listen(
        telegramChatSectionsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await _settle();
      var sections = container.read(telegramChatSectionsProvider);
      expect(sections.pinned.map((chat) => chat.id), [3, 1]);
      expect(sections.other.map((chat) => chat.id), [4, 2]);

      container.read(telegramPreferencesProvider.notifier).pin(3);
      sections = container.read(telegramChatSectionsProvider);
      expect(sections.pinned.map((chat) => chat.id), [1]);
      expect(sections.other.map((chat) => chat.id), [4, 2, 3]);

      container.read(telegramProvider.notifier).search('music');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      sections = container.read(telegramChatSectionsProvider);
      expect(sections.pinned.map((chat) => chat.id), [1]);
      expect(sections.other.map((chat) => chat.id), [4]);
      container.read(telegramProvider.notifier).search('not found');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(container.read(telegramChatSectionsProvider).isEmpty, isTrue);
    },
  );

  test('all download phases are grouped exactly once in insertion order', () {
    final container = createContainer(FakeTelegramRepository());
    final downloads =
        container.read(telegramDownloadsProvider.notifier) as _Downloads;
    for (var index = 0; index < TelegramDownloadPhase.values.length; index++) {
      downloads.put(index, TelegramDownloadPhase.values[index]);
    }
    final sections = container.read(telegramDownloadSectionsProvider);
    expect(
      sections.map((section) => section.group),
      TelegramDownloadGroup.values,
    );
    expect(sections[0].ids, [0, 1, 2]);
    expect(sections[1].ids, [3, 5]);
    expect(sections[2].ids, [4, 6]);
    expect(sections.expand((section) => section.ids).toSet(), {
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    });
  });

  test('download progress does not rebuild sections; moving groups does', () {
    final container = createContainer(FakeTelegramRepository());
    final downloads =
        container.read(telegramDownloadsProvider.notifier) as _Downloads;
    downloads.put(1, TelegramDownloadPhase.receiving);
    var changes = 0;
    final subscription = container.listen(
      telegramDownloadSectionsProvider,
      (_, _) => changes++,
    );
    addTearDown(subscription.close);
    for (var bytes = 1; bytes <= 10; bytes++) {
      downloads.put(1, TelegramDownloadPhase.receiving, received: bytes);
      expect(
        container.read(telegramDownloadSectionsProvider).single.group,
        TelegramDownloadGroup.active,
      );
    }
    downloads.put(1, TelegramDownloadPhase.saving);
    container.read(telegramDownloadSectionsProvider);
    expect(changes, 0);
    downloads.put(1, TelegramDownloadPhase.failed);
    expect(
      container.read(telegramDownloadSectionsProvider).single.group,
      TelegramDownloadGroup.needsAttention,
    );
    expect(changes, 1);
    downloads.put(1, TelegramDownloadPhase.completed);
    expect(
      container.read(telegramDownloadSectionsProvider).single.group,
      TelegramDownloadGroup.finished,
    );
    expect(changes, 2);
  });

  test(
    'avatar initials preserve Persian, emoji graphemes and stable ID colors',
    () {
      expect(TelegramAvatarIdentity(1, '  \u200fموسیقی').initial, 'م');
      expect(TelegramAvatarIdentity(1, ' alice').initial, 'A');
      expect(
        TelegramAvatarIdentity(1, '👨‍👩‍👧‍👦 Family').initial,
        '👨‍👩‍👧‍👦',
      );
      expect(TelegramAvatarIdentity(1, ' \u200f ').initial, isEmpty);
      expect(
        TelegramAvatarIdentity(-1001234567890, 'Old').colorIndex,
        TelegramAvatarIdentity(-1001234567890, 'Renamed').colorIndex,
      );
      expect(
        TelegramAvatarIdentity(-1001234567890, 'Name').colorIndex,
        inInclusiveRange(0, AppAvatarPalette.variants - 1),
      );
    },
  );

  Widget app(
    ProviderContainer container,
    Widget body,
    String locale, {
    double scale = 1,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: body),
    ),
  );

  for (final locale in ['fa', 'en']) {
    testWidgets(
      'chat headers are visible and pinning moves the chat in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = createContainer(chatsRepository());
        await tester.pumpWidget(app(container, const TelegramTab(), locale));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(TelegramTab)),
        );
        expect(find.text(l10n.telegramPinnedChats), findsOneWidget);
        expect(find.text(l10n.telegramOtherChats), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Pinned three')).dy,
          lessThan(tester.getTopLeft(find.text(l10n.telegramOtherChats)).dy),
        );
        expect(
          tester.getTopLeft(find.text('Music other')).dy,
          greaterThan(tester.getTopLeft(find.text(l10n.telegramOtherChats)).dy),
        );
        container.read(telegramPreferencesProvider.notifier).pin(3);
        container.read(telegramPreferencesProvider.notifier).pin(1);
        await tester.pumpAndSettle();
        expect(find.text(l10n.telegramPinnedChats), findsNothing);
        expect(find.text('Music pinned'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('download group headers scroll with large text in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = createContainer(FakeTelegramRepository());
      final downloads =
          container.read(telegramDownloadsProvider.notifier) as _Downloads;
      downloads.put(1, TelegramDownloadPhase.queued);
      downloads.put(2, TelegramDownloadPhase.failed);
      downloads.put(3, TelegramDownloadPhase.completed);
      await tester.pumpWidget(
        app(
          container,
          const TelegramDownloadsView(fill: true),
          locale,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TelegramDownloadsView)),
      );
      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final title in [
        l10n.telegramDownloadsActiveGroup,
        l10n.telegramDownloadsAttentionGroup,
        l10n.telegramDownloadsFinishedGroup,
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          100,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text(title).hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'a missing chat image renders the first letter in a stable palette',
    (tester) async {
      final container = createContainer(FakeTelegramRepository());
      const chat = TelegramChat(
        id: -1001,
        title: 'موسیقی',
        kind: 'chatTypePrivate',
      );
      await tester.pumpWidget(
        app(
          container,
          const Center(child: TelegramChatAvatar(chat: chat)),
          'fa',
          scale: 3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('م'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(TelegramChatAvatar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final colors = AppAvatarPalette.colors(
        AppTheme.light().colorScheme,
        TelegramAvatarIdentity(chat.id, chat.title).colorIndex,
      );
      expect((box.decoration as BoxDecoration).color, colors.background);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
