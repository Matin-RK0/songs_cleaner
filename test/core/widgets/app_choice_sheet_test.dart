import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/widgets/app_choice_sheet.dart';

void main() {
  for (final language in ['en', 'fa']) {
    testWidgets(
      'choice sheet supports large text, cancel and selection in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var result = ThemeMode.system;
        late AppLocalizations l10n;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  l10n = AppLocalizations.of(context);
                  return TextButton(
                    onPressed: () async {
                      final selected = await showAppChoiceSheet<ThemeMode>(
                        context: context,
                        title: l10n.themeModeTitle,
                        current: result,
                        choices: [
                          AppChoice(
                            value: ThemeMode.system,
                            label: l10n.themeModeSystem,
                          ),
                          AppChoice(
                            value: ThemeMode.light,
                            label: l10n.themeModeLight,
                          ),
                          AppChoice(
                            value: ThemeMode.dark,
                            label: l10n.themeModeDark,
                          ),
                        ],
                      );
                      if (selected != null) result = selected;
                    },
                    child: Text(l10n.settingsTitle),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text(l10n.settingsTitle));
        await tester.pumpAndSettle();
        final cancel = find.widgetWithText(OutlinedButton, l10n.cancel);
        expect(cancel.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(result, ThemeMode.system);
        expect(find.byType(BottomSheet), findsNothing);

        await tester.tap(find.text(l10n.settingsTitle));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l10n.themeModeDark));
        await tester.tap(find.text(l10n.themeModeDark));
        await tester.pumpAndSettle();
        expect(result, ThemeMode.dark);
        expect(find.byType(BottomSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
