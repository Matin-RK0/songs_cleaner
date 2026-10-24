import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/widgets/app_color_picker_sheet.dart';

void main() {
  const initialColor = Color(0x40123456);

  Future<AppLocalizations> openPicker(
    WidgetTester tester, {
    required Future<void> Function(Color) onSave,
  }) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => AppColorPickerSheet(
                  initialColor: initialColor,
                  title: 'Pick a color',
                  onSave: onSave,
                ),
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(AppColorPickerSheet)),
    );
  }

  testWidgets('initializes sliders from the RGB channels', (tester) async {
    final savedColors = <Color>[];
    await openPicker(tester, onSave: (color) async => savedColors.add(color));

    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(3));
    expect(tester.widget<Slider>(sliders.at(0)).value, 0x12);
    expect(tester.widget<Slider>(sliders.at(1)).value, 0x34);
    expect(tester.widget<Slider>(sliders.at(2)).value, 0x56);
    expect(savedColors, isEmpty);
  });

  testWidgets('only Save commits the exact opaque color and closes the sheet', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );

    final redSlider = find.byType(Slider).first;
    await tester.tap(redSlider);
    await tester.pump();

    expect(tester.widget<Slider>(redSlider).value, 128);
    expect(savedColors, isEmpty);
    expect(find.byType(AppColorPickerSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.saveAction));
    await tester.pumpAndSettle();

    expect(savedColors, [const Color(0xff803456)]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Cancel closes the sheet without saving slider changes', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );

    final redSlider = find.byType(Slider).first;
    await tester.tap(redSlider);
    await tester.pump();
    expect(tester.widget<Slider>(redSlider).value, 128);

    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    await tester.pumpAndSettle();

    expect(savedColors, isEmpty);
    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
