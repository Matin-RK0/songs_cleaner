import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_motion.dart';
import 'package:songs_cleaner/core/theme/app_player_metrics.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/artwork_image.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/delete_current_button.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_controls_row.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_layout.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_track_info.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/seek_bar.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/artwork_ambient_background.dart';

const _song = Song(
  id: 1,
  title: 'Kalidor',
  artist: 'Armin Barmaye',
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

  void setPlaying(bool value) => state = state.copyWith(playing: value);
}

double _paintedWidth(WidgetTester tester) {
  final artwork = find.byType(ArtworkImage);
  return (tester.getBottomRight(artwork) - tester.getTopLeft(artwork)).dx;
}

void main() {
  for (final hideDelete in [true, false]) {
    for (final reducedMotion in [true, false]) {
      testWidgets(
        'reference artwork proportions; delete hidden: $hideDelete, reduced motion: $reducedMotion',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(412, 892));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final player = _Player();
          final tickerEnabled = ValueNotifier(true);
          addTearDown(tickerEnabled.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                playerProvider.overrideWith(() => player),
                songArtworkProvider.overrideWith((ref, request) async => null),
              ],
              child: MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reducedMotion),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: tickerEnabled,
                    child: child,
                    builder: (_, enabled, child) =>
                        TickerMode(enabled: enabled, child: child!),
                  ),
                ),
                home: Scaffold(
                  body: PlayerLayout(
                    song: _song,
                    hideQuickDelete: hideDelete,
                    header: const SizedBox(height: 48),
                    actions: const SizedBox(height: 48),
                  ),
                ),
              ),
            ),
          );
          await _pumpTransitions(tester);
          final large = 412 * AppPlayerMetrics.artworkWidthFraction;
          expect(tester.widget<Text>(find.text('Kalidor')).style!.fontSize, 18);
          expect(
            tester.widget<Text>(find.text('Armin Barmaye')).style!.fontSize,
            12,
          );
          expect(
            _paintedWidth(tester),
            closeTo(large * AppPlayerMetrics.pausedArtworkScale, 0.01),
          );
          final pausedTitle = tester
              .getTopLeft(find.byType(PlayerTrackInfo))
              .dy;
          final timeline = tester.getTopLeft(find.byType(SeekBar));
          final controls = tester.getTopLeft(find.byType(PlayerControlsRow));
          final metadataWidget = tester.widget(find.byType(PlayerTrackInfo));
          final deletePosition = hideDelete
              ? null
              : tester.getTopLeft(find.byType(DeleteCurrentButton));

          player.setPlaying(true);
          await tester.pump();
          if (!reducedMotion) {
            await tester.pump(AppMotion.slow ~/ 2);
            expect(
              _paintedWidth(tester),
              greaterThan(large * AppPlayerMetrics.pausedArtworkScale),
            );
            expect(_paintedWidth(tester), lessThan(large));
          } else {
            expect(_paintedWidth(tester), closeTo(large, 0.01));
          }
          await _pumpTransitions(tester);
          expect(_paintedWidth(tester), closeTo(large, 0.01));
          expect(
            tester.getTopLeft(find.byType(ArtworkAmbientBackground)).dy,
            greaterThanOrEqualTo(
              tester.getBottomRight(find.byType(ArtworkImage)).dy,
            ),
          );
          expect(
            tester.getTopLeft(find.byType(PlayerTrackInfo)).dy,
            greaterThan(pausedTitle),
          );
          expect(tester.getTopLeft(find.byType(SeekBar)), timeline);
          expect(tester.getTopLeft(find.byType(PlayerControlsRow)), controls);
          expect(
            identical(
              tester.widget(find.byType(PlayerTrackInfo)),
              metadataWidget,
            ),
            isTrue,
          );
          if (!hideDelete) {
            expect(
              tester.getTopLeft(find.byType(DeleteCurrentButton)),
              deletePosition,
            );
          }

          player.setPlaying(false);
          await _pumpTransitions(tester);
          expect(
            _paintedWidth(tester),
            closeTo(large * AppPlayerMetrics.pausedArtworkScale, 0.01),
          );
          expect(
            tester.getTopLeft(find.byType(PlayerTrackInfo)).dy,
            closeTo(pausedTitle, 0.01),
          );
          // Hidden routes should settle immediately, not keep ticking offscreen.
          tickerEnabled.value = false;
          await tester.pump();
          player.setPlaying(true);
          await tester.pump();
          expect(_paintedWidth(tester), closeTo(large, 0.01));
          tickerEnabled.value = true;
          await _pumpTransitions(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _pumpTransitions(WidgetTester tester) async {
  // Ambient lights intentionally loop; settle only finite UI transitions.
  await tester.pump();
  await tester.pump(AppMotion.slow);
}
