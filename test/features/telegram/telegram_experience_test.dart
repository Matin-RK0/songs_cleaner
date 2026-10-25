import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/widgets/music_track_card.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/song_tile.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_artwork_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_chat_library.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_download_sheet.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_track_tile.dart';
import 'telegram_fakes.dart';
import 'telegram_download_controller_test.dart' show FakeDownloadActivity;
import 'telegram_local_matcher_test.dart' show localSong;

class PreviewPlayer extends PlayerController {
  @override
  PlayerState build() => PlayerState.initial;
}

Widget host(
  FakeTelegramRepository repository,
  Widget child, {
  String language = 'en',
}) => ProviderScope(
  overrides: [
    telegramRepositoryProvider.overrideWithValue(repository),
    telegramDownloadActivityProvider.overrideWithValue(FakeDownloadActivity()),
    telegramLocalFilesProvider.overrideWithValue(FakeTelegramLocalFiles()),
    telegramLibrarySyncProvider.overrideWithValue(() async {}),
    allSongsProvider.overrideWithValue([]),
    playerProvider.overrideWith(PreviewPlayer.new),
    telegramArtworkProvider((0, '', '')).overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.5),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets(
    'device and Telegram tracks share the same card and stable row geometry',
    (tester) async {
      final repository = FakeTelegramRepository();
      await tester.pumpWidget(
        host(
          repository,
          Column(
            children: [
              SongTile(song: localSong(), onTap: () {}, showArtwork: false),
              TelegramTrackTile(
                track: TelegramTrack(testAudio()),
                connected: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(MusicTrackCard);
      expect(cards, findsNWidgets(2));
      expect(
        tester.getSize(cards.first).height,
        tester.getSize(cards.last).height,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.dispose();
    },
  );

  testWidgets(
    'download sheet shows measured progress on a small scaled-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeTelegramRepository();
      final audio = testAudio();
      repository.transferGates[audio.fileId] = Completer<void>();
      await tester.pumpWidget(host(repository, const TelegramDownloadDock()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TelegramDownloadDock)),
      );
      repository.events.add(TelegramAuth.ready);
      await tester.pump();
      container.read(telegramDownloadsProvider.notifier).enqueue(audio);
      await tester.pump();
      repository.progressCallbacks[audio.fileId]!(
        const TelegramTransferProgress(received: 100, total: 1000),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(TelegramDownloadDock));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TelegramDownloadsView), findsOneWidget);
      expect(find.textContaining('10%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      repository.transferGates[audio.fileId]!.complete();
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.dispose();
    },
  );

  testWidgets(
    'RTL chat search/filter/selection fits a small viewport with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeTelegramRepository()
        ..preferences = {
          'chat:123': {'localOnly': false},
        }
        ..savedAudio = [for (var i = 1; i <= 6; i++) testAudio(messageId: i)];
      await tester.pumpWidget(
        host(
          repository,
          const TelegramChatLibrary(chatId: 123, connected: false),
          language: 'fa',
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.byType(TelegramTrackTile), findsWidgets);
      expect(tester.takeException(), isNull);
      final track = find.byType(TelegramTrackTile).first;
      await tester.longPress(track);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.dispose();
    },
  );
}
