import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/theme/app_motion.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlist_providers.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlists_controller.dart';
import 'package:songs_cleaner/features/playlists/domain/playlist_order.dart';
import 'package:songs_cleaner/features/playlists/presentation/screens/playlists_tab.dart';

void main() {
  testWidgets('shows the empty state and section headers with no playlists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allSongsProvider.overrideWithValue(const <Song>[]),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const Scaffold(body: PlaylistsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart playlists'), findsOneWidget);
    expect(find.text('My playlists'), findsOneWidget);
    expect(find.text('No playlists yet'), findsOneWidget);
    expect(find.text('New playlist'), findsOneWidget);
  });

  testWidgets(
    'custom lists support search, alphabetical jump, and saved ordering',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 660));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allSongsProvider.overrideWithValue(const <Song>[]),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(playlistsProvider.notifier);
      await controller.create('Astra');
      for (var i = 0; i < 15; i++) {
        await controller.create('Echo $i');
      }
      await controller.create('Zenith');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(body: PlaylistsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'echo');
      await tester.pump(AppMotion.normal);
      await tester.pumpAndSettle();
      expect(find.text('Astra'), findsNothing);
      expect(find.text('Echo 0'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Z'));
      await tester.pumpAndSettle();
      expect(find.text('Zenith'), findsOneWidget);
      await container
          .read(playlistListOrderProvider.notifier)
          .setOrder(PlaylistListOrder.favorites);
      await tester.pumpAndSettle();
      expect(prefs.getString('playlists.listOrder'), 'favorites');
      expect(find.text('Z'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
