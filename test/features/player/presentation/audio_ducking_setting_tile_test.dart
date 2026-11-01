import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/audio_ducking_setting_tile.dart';

void main() {
  for (final language in ['en', 'fa']) {
    testWidgets('previews and saves ducking percentage in $language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = AppSettingsRepository(preferences);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: AudioDuckingSettingTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.audioDuckingPercent(30)), findsOneWidget);

      tester.widget<Slider>(find.byType(Slider)).onChanged!(65);
      await tester.pump();
      expect(find.text(l10n.audioDuckingPercent(65)), findsWidgets);
      expect(repository.loadAudioDuckingPercent(), 30);

      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(65);
      await tester.pumpAndSettle();
      expect(repository.loadAudioDuckingPercent(), 65);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 65);
      expect(tester.takeException(), isNull);
    });
  }
}
