import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/theme/app_color_picker_tokens.dart';
import 'package:songs_cleaner/core/widgets/app_color_picker_sheet.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/widget_background_setting_tile.dart';

void main() {
  const channel = MethodChannel('com.example.songs_cleaner/now_playing_widget');
  const preferenceKey = 'widget.backgroundColor';
  const swatchColor = AppColorPickerTokens.darkNeutral;
  final swatch = find.byKey(const ValueKey('color-picker-swatch-ff30343b'));
  final hex = find.byKey(const ValueKey('color-picker-hex'));
  final calls = <MethodCall>[];
  late SharedPreferences preferences;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<AppLocalizations> pumpTile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: WidgetBackgroundSettingTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold)));
  }

  testWidgets('is Android-only and defaults to dynamic', (tester) async {
    final l10n = await pumpTile(tester);

    expect(find.text(l10n.widgetBackgroundTitle), findsOneWidget);
    expect(find.text(l10n.widgetBackgroundDynamic), findsOneWidget);
    expect(preferences.containsKey(preferenceKey), isFalse);
    expect(calls, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpTile(tester);

    expect(find.byType(WidgetBackgroundSettingTile), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('saves swatch changes and resets to dynamic', (tester) async {
    final l10n = await pumpTile(tester);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump();
    expect(tester.widget<Text>(hex).data, '#30343B');
    expect(preferences.containsKey(preferenceKey), isFalse);
    expect(calls, isEmpty);
    expect(
      find.widgetWithText(FilledButton, l10n.saveAction).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, l10n.saveAction));
    await tester.pumpAndSettle();

    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.text(l10n.widgetBackgroundCustom), findsOneWidget);
    expect(preferences.getInt(preferenceKey), swatchColor.toARGB32());
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setBackgroundColor');
    expect(calls.single.arguments, {'color': swatchColor.toARGB32()});

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(hex).data, '#30343B');
    await tester.tap(
      find.widgetWithText(TextButton, l10n.widgetBackgroundUseDynamic),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.text(l10n.widgetBackgroundDynamic), findsOneWidget);
    expect(preferences.containsKey(preferenceKey), isFalse);
    expect(calls, hasLength(2));
    expect(calls.last.method, 'setBackgroundColor');
    expect(calls.last.arguments, {'color': null});
  });

  testWidgets('cancel discards swatch changes', (tester) async {
    const originalColor = 0xff123456;
    await preferences.setInt(preferenceKey, originalColor);
    final l10n = await pumpTile(tester);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(hex).data, '#123456');
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pump();
    expect(tester.widget<Text>(hex).data, '#30343B');
    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    await tester.pumpAndSettle();

    expect(find.byType(AppColorPickerSheet), findsNothing);
    expect(find.text(l10n.widgetBackgroundCustom), findsOneWidget);
    expect(preferences.getInt(preferenceKey), originalColor);
    expect(calls, isEmpty);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(hex).data, '#123456');
    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    await tester.pumpAndSettle();
  });
}
