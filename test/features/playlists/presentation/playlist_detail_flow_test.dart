import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/app/router/app_router.dart';
import 'package:songs_cleaner/app/router/route_names.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlists_controller.dart';
import 'package:songs_cleaner/features/playlists/domain/playlist_order.dart';
import 'package:songs_cleaner/features/playlists/presentation/screens/playlist_detail_screen.dart';

void main() {
  testWidgets(
    'adds an album and a track, then preserves custom order under sorting',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final library = [
        _song(1, 'Blue Winter', 'Dawn', 10),
        _song(2, 'Violet', 'Dawn', 10),
        _song(3, 'Afterglow', 'Night', 11),
      ];
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allSongsProvider.overrideWithValue(library),
          playerProvider.overrideWith(_Player.new),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(playlistsProvider.notifier);
      final playlist = await controller.create('Mix');
      await controller.addSong(playlist.id, 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: PlaylistDetailScreen(
              args: PlaylistDetailArgs.custom(playlist.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add tracks'));
      await tester.pumpAndSettle();
      expect(find.text('Select tracks'), findsOneWidget);
      expect(find.text('Violet'), findsNothing);

      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dawn'));
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byKey(const ValueKey('1'))).value,
        isTrue,
      );
      await tester.tap(find.text('Afterglow'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add tracks'));
      await tester.pumpAndSettle();
      expect(controller.playlistById(playlist.id)!.songIds, [2, 1, 3]);

      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pumpAndSettle();
      expect(controller.playlistById(playlist.id)!.isFavorite, isTrue);
      await tester.tap(find.text('Custom order'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('By title'),
          matching: find.byType(CheckedPopupMenuItem<PlaylistTrackOrder>),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        controller.playlistById(playlist.id)!.trackOrder,
        PlaylistTrackOrder.title,
      );
      expect(controller.playlistById(playlist.id)!.songIds, [2, 1, 3]);
      expect(
        tester.getTopLeft(find.text('Afterglow')).dy,
        lessThan(tester.getTopLeft(find.text('Blue Winter')).dy),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey(3)),
          matching: find.byTooltip('More actions'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View album'), findsOneWidget);
      expect(find.text('View artist'), findsOneWidget);
      await tester.tap(find.text('Remove from playlist'));
      await tester.pumpAndSettle();
      expect(controller.playlistById(playlist.id)!.songIds, [2, 1]);

      final title = find.text('Blue Winter');
      final row = find.byKey(const ValueKey(1));
      double upperGap() =>
          tester.getTopLeft(title).dy - tester.getTopLeft(row).dy;
      final normalGap = upperGap();
      await tester.longPress(title);
      await tester.pumpAndSettle();
      expect(upperGap(), lessThan(normalGap));
      expect(tester.takeException(), isNull);
    },
  );
}

class _Player extends PlayerController {
  @override
  PlayerState build() => PlayerState.initial;
}

Song _song(int id, String title, String album, int albumId) => Song(
  id: id,
  title: title,
  album: album,
  albumId: albumId,
  artist: 'Artist',
  artistId: 1,
  duration: const Duration(minutes: 2),
  path: '/music/$id.mp3',
  sizeBytes: 12,
  dateAddedSeconds: id,
);
