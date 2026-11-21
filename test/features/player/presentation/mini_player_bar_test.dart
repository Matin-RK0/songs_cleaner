import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/artwork_image.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/mini_player_bar.dart';

void main() {
  for (final language in ['en', 'fa']) {
    testWidgets('compact playback and seek controls work in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final player = _Player();
      final cover = language == 'en'
          ? base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            )
          : null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith(() => player),
            songArtworkProvider.overrideWith((ref, key) async => cover),
          ],
          child: MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(language == 'fa' ? 2 : 1),
              ),
              child: child!,
            ),
            home: const Scaffold(bottomNavigationBar: MiniPlayerBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.getRect(find.byType(MiniPlayerBar));
      final thumbnail = tester.getRect(find.byType(ArtworkImage));
      expect(card.height, 104);
      expect(thumbnail.top - card.top, 12);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.excludeFromSemantics,
        ),
        cover != null ? findsOneWidget : findsNothing,
      );
      expect(find.text(_first.title), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      final strip = tester.getRect(find.byType(LinearProgressIndicator));
      expect(
        language == 'fa' ? thumbnail.right : thumbnail.left,
        language == 'fa' ? strip.right : strip.left,
      );
      final visualFraction = language == 'fa' ? 0.75 : 0.25;
      await tester.tapAt(
        Offset(strip.left + strip.width * visualFraction, strip.center.dy),
      );
      await tester.pumpAndSettle();
      expect(player.lastSeek, const Duration(seconds: 25));

      await tester.drag(find.text(_first.title), const Offset(-130, 0));
      await tester.pumpAndSettle();
      expect(player.nextCalls, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

const _first = Song(
  id: 1,
  title: 'A long track title',
  artist: 'First artist',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(seconds: 100),
  path: '/music/1.mp3',
  sizeBytes: 1,
  dateAddedSeconds: 1,
);
const _second = Song(
  id: 2,
  title: 'Next track',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(seconds: 100),
  path: '/music/2.mp3',
  sizeBytes: 1,
  dateAddedSeconds: 1,
);

class _Player extends PlayerController {
  Duration? lastSeek;
  int nextCalls = 0;

  @override
  PlayerState build() => const PlayerState(
    songs: [_first, _second],
    index: 0,
    duration: Duration(seconds: 100),
  );

  @override
  Future<void> playPause() async =>
      state = state.copyWith(playing: !state.playing);

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    state = state.copyWith(position: position);
  }

  @override
  Future<void> next() async => nextCalls++;
}
