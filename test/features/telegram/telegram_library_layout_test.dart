import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/widgets/app_state_views.dart';
import 'package:songs_cleaner/core/widgets/music_track_card.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/song_tile.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_chat_library.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_selection_overlay.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_track_tile.dart';

import 'telegram_experience_test.dart' show host;
import 'telegram_fakes.dart';
import 'telegram_local_matcher_test.dart' show localSong;

class _LoadingRepository extends FakeTelegramRepository {
  final cachedPage = Completer<List<TelegramAudio>>();

  @override
  Future<List<TelegramAudio>> cachedAudio(int chatId) => cachedPage.future;
}

void main() {
  testWidgets('initial music loading does not also show an empty state', (
    tester,
  ) async {
    final repository = _LoadingRepository();
    await tester.pumpWidget(
      host(
        repository,
        const TelegramChatLibrary(chatId: 123, connected: false),
      ),
    );
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(AppEmptyState), findsNothing);
    repository.cachedPage.complete([]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.dispose();
  });

  testWidgets('selection actions scroll above the system bottom inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                Flexible(
                  child: TelegramSelectionOverlay(
                    visible: true,
                    child: Column(
                      children: [
                        for (var i = 0; i < 10; i++)
                          ListTile(title: Text('Action $i')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Action 9'));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('Action 9')).dy, lessThan(600 - 34));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned music filters accommodate triple-sized text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeTelegramRepository();
    await tester.pumpWidget(
      host(
        repository,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(3)),
            child: const TelegramChatLibrary(chatId: 123, connected: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.dispose();
  });

  testWidgets('all eight song actions remain reachable in a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeTelegramRepository();
    var deleted = false;
    await tester.pumpWidget(
      host(
        repository,
        SongTile(
          song: localSong(),
          onTap: () {},
          showArtwork: false,
          showMoreButton: true,
          onShowInfo: () {},
          onAddToPlaylist: (_) {},
          onToggleFavorite: () {},
          onDeleteDevice: (_) => deleted = true,
          extraActions: [
            (icon: Icons.open_in_new, label: 'Open message', action: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(8));
    expect(tester.takeException(), isNull);
    final delete = find.byIcon(Icons.delete_outline_rounded);
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.dispose();
  });

  testWidgets('selected track exposes selected semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicTrackCard(
            title: 'Track',
            subtitle: const Text('Artist'),
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );
    final selected = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.selected == true,
    );
    expect(selected, findsOneWidget);
    expect(
      tester.getSemantics(selected),
      isSemantics(isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('selection allocates space and keeps the last track reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeTelegramRepository()
      ..preferences = {
        'chat:123': {'localOnly': false},
      }
      ..savedAudio = [for (var i = 1; i <= 12; i++) testAudio(messageId: i)];
    await tester.pumpWidget(
      host(
        repository,
        const TelegramChatLibrary(chatId: 123, connected: false),
        language: 'fa',
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TelegramChatLibrary)),
    );
    container
        .read(telegramChatProvider(123).notifier)
        .toggleSelection(repository.savedAudio.first.key);
    await tester.pumpAndSettle();
    final viewport = find.byType(CustomScrollView);
    final toolbar = find.byType(TelegramSelectionOverlay);
    expect(
      tester.getBottomLeft(viewport).dy,
      lessThanOrEqualTo(tester.getTopLeft(toolbar).dy),
    );
    await tester.drag(viewport, const Offset(0, -3000));
    await tester.pumpAndSettle();
    final last = find.byKey(ValueKey(repository.savedAudio.last.key));
    expect(last, findsOneWidget);
    expect(
      tester.getBottomLeft(last).dy,
      lessThanOrEqualTo(tester.getTopLeft(toolbar).dy),
    );
    expect(find.byType(TelegramTrackTile), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.dispose();
  });

  testWidgets('failed initial load does not also show a music empty state', (
    tester,
  ) async {
    final repository = FakeTelegramRepository()
      ..failure = TelegramFailure.generic;
    await tester.pumpWidget(
      host(repository, const TelegramChatLibrary(chatId: 123, connected: true)),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TelegramChatLibrary)),
    );
    container.read(telegramProvider);
    await tester.pumpAndSettle();
    repository.events.add(TelegramAuth.ready);
    await tester.pumpAndSettle();
    await container.read(telegramChatProvider(123).notifier).refresh();
    await tester.pumpAndSettle();
    expect(container.read(telegramChatProvider(123)).failure, isNotNull);
    expect(find.byType(AppEmptyState), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.dispose();
  });

  testWidgets(
    'music search uses the generic result copy rather than chat copy',
    (tester) async {
      final repository = FakeTelegramRepository()
        ..preferences = {
          'chat:123': {'query': 'missing', 'localOnly': false},
        };
      await tester.pumpWidget(
        host(
          repository,
          const TelegramChatLibrary(chatId: 123, connected: false),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TelegramChatLibrary)),
    );
      expect(find.text(l10n.noResultsTitle), findsOneWidget);
      expect(find.text(l10n.telegramNoResults), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.dispose();
    },
  );
}
