import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_controls_row.dart';

Song _song(int id) => Song(
  id: id,
  title: 'Track $id',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: const Duration(seconds: 60),
  path: '/$id.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Player extends PlayerController {
  int nextCalls = 0;
  int previousCalls = 0;

  @override
  PlayerState build() => PlayerState(songs: [_song(1)], index: 0);

  void addTrack() => state = state.copyWith(songs: [_song(1), _song(2)]);

  @override
  Future<void> next() async {
    nextCalls++;
  }

  @override
  Future<void> previous() async {
    previousCalls++;
  }
}

void main() {
  for (final language in ['en', 'fa']) {
    testWidgets('transport availability follows queue size in $language', (
      tester,
    ) async {
      final player = _Player();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playerProvider.overrideWith(() => player)],
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: PlayerControlsRow()),
          ),
        ),
      );
      final next = find.widgetWithIcon(IconButton, Icons.skip_next_rounded);
      final previous = find.widgetWithIcon(
        IconButton,
        Icons.skip_previous_rounded,
      );
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      expect(tester.widget<IconButton>(previous).onPressed, isNull);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.play_arrow_rounded),
            )
            .onPressed,
        isNotNull,
      );

      player.addTrack();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      expect(tester.widget<IconButton>(previous).onPressed, isNotNull);
      await tester.tap(next);
      await tester.tap(previous);
      expect(player.nextCalls, 1);
      expect(player.previousCalls, 1);
    });
  }
}
