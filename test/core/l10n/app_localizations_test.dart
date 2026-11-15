import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';

void main() {
  for (final language in ['en', 'fa']) {
    testWidgets(
      'generated delegates provide modern UI localizations in $language',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) {
                expect(
                  MaterialLocalizations.of(context).okButtonLabel,
                  isNotEmpty,
                );
                expect(AppLocalizations.of(context).localeName, language);
                expect(CupertinoLocalizations.of(context), isNotNull);
                expect(
                  WidgetsLocalizations.of(context).textDirection,
                  language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
                );
                return Text(AppLocalizations.of(context).holdToDeleteAction);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == 'fa'
                ? 'برای حذف نگه دارید'
                : 'Hold to delete from device',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
