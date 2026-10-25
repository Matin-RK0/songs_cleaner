import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/playlists/presentation/widgets/playlist_name_sheet.dart';

void main() {
  for (final keyboardHeight in [0.0, 300.0]) {
    testWidgets(
      'name actions avoid system insets with keyboard $keyboardHeight',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.viewPadding = const FakeViewPadding(bottom: 34);
        tester.view.padding = FakeViewPadding(
          bottom: keyboardHeight == 0 ? 34 : 0,
        );
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fa'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showPlaylistNameSheet(
                    context: context,
                    title: 'New playlist',
                    actionLabel: 'Create',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final submit = find.widgetWithText(FilledButton, 'Create');
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(
          tester.getBottomLeft(submit).dy,
          lessThanOrEqualTo(800 - (keyboardHeight == 0 ? 34 : keyboardHeight)),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

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
