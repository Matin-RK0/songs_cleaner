import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_auth_screen.dart';

import 'telegram_fakes.dart';

void main() {
  test(
    'phone edit resubmits phone while TDLib is waiting for a code',
    () async {
      final repository = FakeTelegramRepository();
      final container = ProviderContainer(
        overrides: [telegramRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);
      final controller = container.read(telegramProvider.notifier);
      await controller.connect();
      await controller.submit('+989121234567');
      controller.editPhone();
      expect(container.read(telegramProvider).auth, TelegramAuth.code);
      expect(container.read(telegramProvider).authStep, TelegramAuth.phone);
      expect(container.read(telegramProvider).phone, '+989121234567');

      repository.failure = TelegramFailure.phone;
      await controller.submit('invalid');
      expect(container.read(telegramProvider).editingPhone, isTrue);
      expect(container.read(telegramProvider).phone, '+989121234567');
      expect(container.read(telegramProvider).failure, TelegramFailure.phone);

      repository.failure = null;
      await controller.submit('+989351234567');
      expect(repository.submittedPhones.last, '+989351234567');
      expect(container.read(telegramProvider).authStep, TelegramAuth.code);
      expect(container.read(telegramProvider).phone, '+989351234567');
      expect(container.read(telegramProvider).failure, isNull);
      await controller.submit('12345');
      expect(container.read(telegramProvider).auth, TelegramAuth.password);
    },
  );

  test('editing cannot interrupt a pending submission', () async {
    final repository = FakeTelegramRepository();
    final container = ProviderContainer(
      overrides: [telegramRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    final controller = container.read(telegramProvider.notifier);
    await controller.connect();
    await controller.submit('+989121234567');
    controller.editPhone();
    repository.pendingPhone = Completer<void>();
    final pending = controller.submit('+989351234567');
    controller.cancelPhoneEdit();
    await controller.submit('+989991234567');
    expect(container.read(telegramProvider).editingPhone, isTrue);
    expect(repository.submittedPhones, hasLength(2));
    repository.pendingPhone!.complete();
    await pending;
    expect(container.read(telegramProvider).editingPhone, isFalse);
  });

  for (final locale in ['en', 'fa']) {
    testWidgets('edit and back navigation work in $locale', (tester) async {
      final repository = FakeTelegramRepository();
      addTearDown(repository.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [telegramRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.light(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const TelegramAuthScreen()),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TelegramAuthScreen)),
      );
      await tester.enterText(find.byType(TextField), '+989121234567');
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.telegramSendCode),
      );
      await tester.pumpAndSettle();
      expect(find.text('+989121234567'), findsOneWidget);
      await tester.tap(find.text(l10n.telegramEditPhone));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '+989121234567',
      );
      await tester.tap(find.text(l10n.telegramReturnToCode));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(l10n.telegramSendCode), findsOneWidget);
      await tester.enterText(find.byType(TextField), '+989351234567');
      await tester.tap(find.text(l10n.telegramSendCode));
      await tester.pumpAndSettle();
      expect(find.text('+989351234567'), findsOneWidget);
      expect(repository.submittedPhones, ['+989121234567', '+989351234567']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TelegramAuthScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
