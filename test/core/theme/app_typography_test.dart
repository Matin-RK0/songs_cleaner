import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/theme/app_typography.dart';

void main() {
  test('Roboto and Persian fallback reach theme and component styles', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      for (final style in [
        theme.textTheme.bodyMedium!,
        theme.appBarTheme.titleTextStyle!,
        theme.snackBarTheme.contentTextStyle!,
        theme.tabBarTheme.labelStyle!,
        theme.dialogTheme.titleTextStyle!,
        theme.dialogTheme.contentTextStyle!,
        AppTypography.nowPlayingTitle,
        AppTypography.nowPlayingArtist,
        AppTypography.nowPlayingTime,
      ]) {
        expect(style.fontFamily, 'Roboto');
        expect(style.fontFamilyFallback, contains('Vazirmatn'));
      }
    }
  });

  testWidgets(
    'bundled fonts load offline and render mixed Persian/Latin with large text',
    (tester) async {
      final roboto = FontLoader('Roboto');
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ]) {
        roboto.addFont(
          rootBundle.load('assets/fonts/roboto/Roboto-$weight.ttf'),
        );
      }
      final persian = FontLoader('Vazirmatn')
        ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
      await tester.runAsync(() async {
        await Future.wait([roboto.load(), persian.load()]);
        // Font loading sends a platform notification on the next event turn.
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      final license = await rootBundle.loadString(
        'assets/fonts/roboto/OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('fa'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: Column(
              children: [
                Text('Kalidor — موسیقی', style: AppTypography.nowPlayingTitle),
                Text('Artist — خواننده', style: AppTypography.nowPlayingArtist),
                Text('2:00 / 5:00', style: AppTypography.nowPlayingTime),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Kalidor — موسیقی'), findsOneWidget);
    },
  );
}
