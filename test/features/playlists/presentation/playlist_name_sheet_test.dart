import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/playlists/presentation/widgets/playlist_name_sheet.dart';

void main() {
  testWidgets('disables submit when empty and returns the trimmed name', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showPlaylistNameSheet(
                    context: context,
                    title: 'New playlist',
                    actionLabel: 'Create',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Create');
    expect(submit, findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Chill  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(result, 'Chill');
  });
}
