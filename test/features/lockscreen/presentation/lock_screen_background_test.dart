import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/lockscreen/presentation/widgets/lock_screen_background.dart';

void main() {
  const channel = MethodChannel('com.example.songs_cleaner/lock_screen');
  final calls = <String>[];
  var status = 'locked';

  setUp(() {
    calls.clear();
    status = 'locked';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'lockScreen' ? status : true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LockScreenBackground(
            child: Center(
              child: TextButton(onPressed: () {}, child: const Text('Play')),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> doubleTapBackground(WidgetTester tester) async {
    await tester.tapAt(const Offset(20, 100));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();
  }

  testWidgets('only a background double tap requests screen lock', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await doubleTapBackground(tester);
    expect(calls, ['lockScreen']);
  });

  testWidgets('permission settings require explicit consent', (tester) async {
    status = 'permissionRequired';
    await pumpScreen(tester);
    await doubleTapBackground(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(calls, ['lockScreen']);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(calls, ['lockScreen']);

    await doubleTapBackground(tester);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(calls, ['lockScreen', 'lockScreen', 'requestScreenLockAccess']);
  });

  testWidgets(
    'revoked access prompts again instead of assuming it is granted',
    (tester) async {
      await pumpScreen(tester);
      await doubleTapBackground(tester);
      status = 'permissionRequired';
      await doubleTapBackground(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(calls, ['lockScreen', 'lockScreen']);
    },
  );

  testWidgets('a single background tap does not lock', (tester) async {
    await pumpScreen(tester);
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });
}
