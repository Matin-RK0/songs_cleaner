import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/application/providers/library_stats_controller.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/library_stats.dart';
import 'package:songs_cleaner/features/player/application/providers/player_preferences_controller.dart';
import 'package:songs_cleaner/features/player/presentation/screens/player_screen.dart';
import 'package:songs_cleaner/features/lockscreen/presentation/screens/lock_screen_player_screen.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/queue_sheet.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_layout.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_controls_row.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/seek_bar.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/delete_current_button.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';

const _song = Song(
  id: 1,
  title: 'A long track title that wraps onto a second line',
  artist: 'Artist',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(minutes: 3),
  path: '/1.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Player extends PlayerController {
  @override
  PlayerState build() => const PlayerState(songs: [_song], index: 0);
}

class _Stats extends LibraryStatsController {
  @override
  LibraryStats build() => LibraryStats.empty;
}

class _HideDelete extends HideQuickDeleteController {
  @override
  bool build() => true;
}

void main() {
  for (final locked in [false, true]) {
    testWidgets('active player renders safely, locked: $locked', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith(_Player.new),
            libraryStatsProvider.overrideWith(_Stats.new),
            hideQuickDeleteProvider.overrideWith(_HideDelete.new),
            songArtworkProvider.overrideWith((ref, request) async => null),
          ],
          child: MaterialApp(
            locale: const Locale('fa'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: locked
                ? const LockScreenPlayerScreen()
                : const PlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(
        find.byIcon(Icons.add_rounded),
        locked ? findsNothing : findsOneWidget,
      );
      if (!locked) {
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate((widget) => widget is PopupMenuItem),
          findsNWidgets(5),
        );
        // Dismiss the menu, then verify the queue retains transport controls.
        await tester.tapAt(const Offset(10, 400));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.queue_music_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(QueueSheetContent), findsOneWidget);
        expect(find.text('1/1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
  for (final size in [
    const Size(320, 568),
    const Size(412, 892),
    const Size(740, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final hideDelete in [true, false]) {
        testWidgets('layout $size scale $scale hideDelete $hideDelete', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                playerProvider.overrideWith(_Player.new),
                songArtworkProvider.overrideWith((ref, request) async => null),
              ],
              child: MaterialApp(
                locale: const Locale('fa'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SafeArea(
                    child: PlayerLayout(
                      song: _song,
                      hideQuickDelete: hideDelete,
                      header: const SizedBox(height: 48),
                      actions: const SizedBox(height: 48),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(PlayerControlsRow), findsOneWidget);
          expect(find.byType(SeekBar), findsOneWidget);
          expect(
            find.byType(DeleteCurrentButton),
            hideDelete ? findsNothing : findsOneWidget,
          );
          if (!hideDelete) {
            final controlsBottom = tester
                .getBottomLeft(find.byType(PlayerControlsRow))
                .dy;
            final deleteTop = tester
                .getTopLeft(find.byType(DeleteCurrentButton))
                .dy;
            expect(deleteTop - controlsBottom, AppSpacing.lg);
          }
          final contentBottom = tester
              .getBottomLeft(find.byType(PlayerLayout))
              .dy;
          final lastBottom = tester
              .getBottomLeft(
                find.byType(
                  hideDelete ? PlayerControlsRow : DeleteCurrentButton,
                ),
              )
              .dy;
          if (size.height >= 892 && scale == 1) {
            expect(contentBottom - lastBottom, AppSpacing.lg);
          }
          expect(
            tester.getTopLeft(find.byType(SeekBar)).dy,
            lessThan(tester.getTopLeft(find.byType(PlayerControlsRow)).dy),
          );
        });
      }
    }
  }
}
