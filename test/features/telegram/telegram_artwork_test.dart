import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_artwork_provider.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_artwork.dart';
import 'telegram_fakes.dart';

void main() {
  testWidgets('cloud music renders a Telegram cover without a local audio file', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final track = TelegramTrack(testAudio());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telegramArtworkProvider((
            0,
            '',
            '',
          )).overrideWith((ref) async => bytes),
        ],
        child: MaterialApp(
          home: Scaffold(body: TelegramArtwork(track: track)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<ResizeImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('music without artwork keeps a stable music/cloud placeholder', (
    tester,
  ) async {
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
          home: Scaffold(
            body: TelegramArtwork(track: TelegramTrack(testAudio())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
