import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_tab.dart';
import 'telegram_fakes.dart';

void main() {
  for (final locale in ['fa', 'en']) {
    testWidgets(
      'Telegram empty state scrolls on small $locale screens with large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = FakeTelegramRepository();
        addTearDown(repository.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              telegramRepositoryProvider.overrideWithValue(repository),
              allSongsProvider.overrideWithValue([]),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const Scaffold(body: TelegramTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.telegram_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
