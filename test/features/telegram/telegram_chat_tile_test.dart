import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_artwork_provider.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_chat_avatar.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_chat_tile.dart';

void main() {
  testWidgets(
    'profile photo uses the enlarged avatar and keeps chat navigation',
    (tester) async {
      const chat = TelegramChat(
        id: 1,
        title: 'Music',
        kind: 'chatTypePrivate',
        photoFileId: 45,
      );
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      var tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telegramArtworkProvider((
              45,
              '',
              '',
            )).overrideWith((ref) async => bytes),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TelegramChatTile(chat: chat, onTap: () => tapped = true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(TelegramChatAvatar)),
        const Size.square(AppSpacing.avatarLarge),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>(),
      );
      await tester.tap(find.text('Music'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large RTL chat tile fits a small screen with long names and scaled text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const chat = TelegramChat(
        id: 1,
        title: 'کانال موسیقی با نام بسیار بلند برای بررسی نمایش در صفحه کوچک',
        kind: 'chatTypeSupergroup',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telegramArtworkProvider((
              0,
              '',
              '',
            )).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            locale: const Locale('fa'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: ListView(
                padding: AppSpacing.allMd,
                children: [TelegramChatTile(chat: chat, onTap: () {})],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ک'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TelegramChatTile)).height,
        greaterThan(AppSpacing.avatarLarge),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
