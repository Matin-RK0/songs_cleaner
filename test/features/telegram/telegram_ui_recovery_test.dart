import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_auth_input.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_auth_screen.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_tab.dart';

import 'telegram_fakes.dart';

class _RecoveringAuth extends FakeTelegramRepository {
  @override
  Future<void> connect() async {
    connectCalls++;
    if (connectCalls == 1) {
      events.add(TelegramAuth.starting);
      throw const TelegramException(TelegramFailure.network);
    }
    events.add(TelegramAuth.phone);
  }
}

class _PendingChats extends FakeTelegramRepository {
  final pending = Completer<List<TelegramChat>>();
  @override
  Future<List<TelegramChat>> chats({bool more = false}) => pending.future;
}

void main() {
  test(
    'phone and code normalize localized digits without hiding bad input',
    () {
      expect(
        TelegramAuthInput.phone(' ‎+۹۸ (۹۱۲) ۱۲۳-۴۵۶۷‎ '),
        '+989121234567',
      );
      expect(TelegramAuthInput.phone('+٩٨٩١٢١٢٣٤٥٦٧'), '+989121234567');
      expect(TelegramAuthInput.phone('+98oops912'), '+98oops912');
      expect(TelegramAuthInput.code(' ۱۲۳٤٥ '), '12345');
    },
  );

  ProviderContainer containerFor(FakeTelegramRepository repository) {
    final container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        allSongsProvider.overrideWithValue([]),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    return container;
  }

  Widget app(ProviderContainer container, Widget child) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  testWidgets('startup failure replaces spinner with usable reconnect', (
    tester,
  ) async {
    final repository = _RecoveringAuth();
    final container = containerFor(repository);
    await tester.pumpWidget(app(container, const TelegramAuthScreen()));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TelegramAuthScreen)),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(l10n.telegramErrorNetwork), findsOneWidget);
    await tester.tap(find.text(l10n.telegramReconnect));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l10n.telegramErrorNetwork), findsNothing);
    expect(repository.connectCalls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chat loading does not also claim the account is empty', (
    tester,
  ) async {
    final repository = _PendingChats();
    final container = containerFor(repository);
    container.read(telegramProvider);
    repository.events.add(TelegramAuth.ready);
    await tester.pumpWidget(
      app(container, const Scaffold(body: TelegramTab())),
    );
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsNothing);
    repository.pending.complete([]);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byIcon(Icons.forum_outlined),
      150,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chat search survives remount and can be visibly cleared', (
    tester,
  ) async {
    final container = containerFor(FakeTelegramRepository());
    container.read(telegramProvider.notifier).search('music');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(
      app(container, const Scaffold(body: TelegramTab())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'music',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      app(container, const Scaffold(body: TelegramTab())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'music',
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(TelegramTab)));
    await tester.ensureVisible(find.byTooltip(l10n.telegramClearSearch));
    await tester.tap(find.byTooltip(l10n.telegramClearSearch));
    await tester.pumpAndSettle();
    expect(container.read(telegramProvider).query, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
