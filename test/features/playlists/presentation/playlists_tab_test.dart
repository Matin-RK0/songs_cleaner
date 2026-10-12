import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
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
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
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
}
