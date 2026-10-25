import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_color_picker_tokens.dart';
import 'package:songs_cleaner/core/widgets/app_color_picker_sheet.dart';

void main() {
  const initialColor = Color(0x40123456);
  const swatchColor = AppColorPickerTokens.darkNeutral;
  final swatch = find.byKey(const ValueKey('color-picker-swatch-ff30343b'));
  final hex = find.byKey(const ValueKey('color-picker-hex'));

  Finder preview(String label, String hex) => find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == '$label $hex',
  );

  Future<AppLocalizations> openPicker(
    WidgetTester tester, {
    required Future<void> Function(Color) onSave,
    Size size = const Size(1000, 1200),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
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

  testWidgets('initializes before, after and hex to the exact opaque color', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );

    expect(tester.widget<Text>(hex).data, '#123456');
    expect(preview(l10n.colorBefore, '#123456'), findsOneWidget);
    expect(preview(l10n.colorAfter, '#123456'), findsOneWidget);
    expect(savedColors, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, l10n.saveAction));
    await tester.pumpAndSettle();

    expect(savedColors, [const Color(0xff123456)]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
  });

  testWidgets('only Save commits the exact opaque color and closes the sheet', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );

    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump();

    expect(tester.widget<Text>(hex).data, '#30343B');
    expect(preview(l10n.colorBefore, '#123456'), findsOneWidget);
    expect(preview(l10n.colorAfter, '#30343B'), findsOneWidget);
    expect(savedColors, isEmpty);
    expect(find.byType(AppColorPickerSheet), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.saveAction).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, l10n.saveAction));
    await tester.pumpAndSettle();

    expect(savedColors, [swatchColor]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Cancel closes the sheet without saving swatch changes', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );

    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump();
    expect(tester.widget<Text>(hex).data, '#30343B');

    await tester.tap(find.widgetWithText(OutlinedButton, l10n.cancel));
    await tester.pumpAndSettle();

    expect(savedColors, isEmpty);
    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('visual plane changes only the draft until Save', (tester) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
    );
    final field = find.byKey(const ValueKey('color-picker-sv-field'));
    expect(tester.widget<Text>(hex).data, '#123456');

    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pump();

    final draftHex = tester.widget<Text>(hex).data!;
    expect(draftHex, isNot('#123456'));
    expect(preview(l10n.colorBefore, '#123456'), findsOneWidget);
    expect(preview(l10n.colorAfter, draftHex), findsOneWidget);
    expect(savedColors, isEmpty);
    expect(find.byType(AppColorPickerSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.saveAction));
    await tester.pumpAndSettle();

    expect(savedColors, [
      Color(int.parse('ff${draftHex.substring(1)}', radix: 16)),
    ]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
  });

  testWidgets('narrow RTL sheet scrolls swatches with Save always visible', (
    tester,
  ) async {
    final savedColors = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async => savedColors.add(color),
      size: const Size(320, 568),
      locale: const Locale('fa'),
    );
    final save = find.widgetWithText(FilledButton, l10n.saveAction);
    expect(
      Directionality.of(tester.element(find.byType(AppColorPickerSheet))),
      TextDirection.rtl,
    );
    expect(tester.widget<Text>(hex).textDirection, TextDirection.ltr);
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(hex).data, '#30343B');
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(savedColors, isEmpty);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(savedColors, [swatchColor]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
  });

  testWidgets(
    'fine adjustments are optional and keep the draft when collapsed',
    (tester) async {
      final savedColors = <Color>[];
      final l10n = await openPicker(
        tester,
        onSave: (color) async => savedColors.add(color),
      );
      final toggle = find.byKey(
        const ValueKey('color-picker-fine-adjustments'),
      );
      final saturation = find.byKey(const ValueKey('color-picker-saturation'));
      final brightness = find.byKey(const ValueKey('color-picker-brightness'));
      expect(saturation, findsNothing);
      expect(brightness, findsNothing);

      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      expect(saturation, findsOneWidget);
      expect(brightness, findsOneWidget);
      await tester.ensureVisible(brightness);
      await tester.tap(brightness);
      await tester.pump();
      final draftHex = tester.widget<Text>(hex).data;

      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      expect(saturation, findsNothing);
      expect(brightness, findsNothing);
      expect(tester.widget<Text>(hex).data, draftHex);
      expect(savedColors, isEmpty);
      await tester.tap(find.widgetWithText(OutlinedButton, l10n.cancel));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('neutral swatches retain the selected hue', (tester) async {
    final l10n = await openPicker(tester, onSave: (_) async {});
    final hue = find.byKey(const ValueKey('color-picker-hue'));
    final originalHue = tester.widget<Slider>(hue).value;
    final black = find.byKey(const ValueKey('color-picker-swatch-ff000000'));
    await tester.ensureVisible(black);
    await tester.tap(black);
    await tester.pump();

    expect(tester.widget<Slider>(hue).value, originalHue);
    expect(tester.widget<Text>(hex).data, '#000000');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.cancel));
    await tester.pumpAndSettle();
  });

  testWidgets('failed Save can retry and ignores duplicate submissions', (
    tester,
  ) async {
    final pending = Completer<void>();
    final attempts = <Color>[];
    final l10n = await openPicker(
      tester,
      onSave: (color) async {
        attempts.add(color);
        if (attempts.length == 1) await pending.future;
      },
    );
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump();
    final save = find.widgetWithText(FilledButton, l10n.saveAction);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();

    expect(attempts, [swatchColor]);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, l10n.cancel),
          )
          .onPressed,
      isNull,
    );
    expect(tester.widget<IconButton>(swatch).onPressed, isNull);

    pending.completeError(StateError('private save failure'));
    await tester.pumpAndSettle();

    expect(find.byType(AppColorPickerSheet), findsOneWidget);
    expect(find.text(l10n.errorLoadFailedMessage), findsOneWidget);
    expect(find.textContaining('private save failure'), findsNothing);
    expect(tester.widget<Text>(hex).data, '#30343B');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(attempts, [swatchColor, swatchColor]);
    expect(find.byType(AppColorPickerSheet), findsNothing);
  });
}
