import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/utils/alphabet_index.dart';
import 'package:songs_cleaner/core/widgets/alphabet_index_rail.dart';

void main() {
  test(
    'initials use the first row in display order and handle mixed scripts',
    () {
      expect(
        buildAlphabetIndex([
          '99',
          ':',
          'apple',
          'Atlas',
          'Étoile',
          'آباد',
          'انار',
          'كتاب',
          'کار',
          'یاس',
        ]),
        {'#': 0, 'A': 2, 'É': 4, 'ا': 5, 'ک': 7, 'ی': 9},
      );
    },
  );

  testWidgets('tap and vertical drag jump to corresponding rows', (
    tester,
  ) async {
    final jumps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: SizedBox()),
              AlphabetIndexRail(
                index: const {'A': 0, 'B': 15, 'C': 40},
                onJump: jumps.add,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    expect(jumps, [15]);
    final start = tester.getCenter(find.text('A'));
    final end = tester.getCenter(find.text('C'));
    final drag = await tester.startGesture(start);
    await drag.moveTo(tester.getCenter(find.text('B')));
    await tester.pump();
    await drag.moveTo(end);
    await drag.up();
    expect(jumps.last, 40);
  });
}
