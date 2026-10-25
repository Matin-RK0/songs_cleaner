import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/lockscreen/presentation/screens/lock_screen_player_screen.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/application/providers/player_preferences_controller.dart';

class _IdlePlayer extends PlayerController {
  @override
  PlayerState build() => PlayerState.initial;
}

class _HideQuickDelete extends HideQuickDeleteController {
  @override
  bool build() => true;
}

void main() {
  const channel = MethodChannel('com.example.songs_cleaner/lock_screen');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'lockScreen' ? 'locked' : null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<NavigatorState> openPlayer(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerProvider.overrideWith(_IdlePlayer.new),
          hideQuickDeleteProvider.overrideWith(_HideQuickDelete.new),
        ],
        child: MaterialApp(
          navigatorKey: key,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Text('Library')),
        ),
      ),
    );
    key.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const LockScreenPlayerScreen()),
    );
    await tester.pumpAndSettle();
    return key.currentState!;
  }

  testWidgets('Back retains the player until native confirms unlock', (
    tester,
  ) async {
    final navigator = await openPlayer(tester);

    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(calls, ['dismiss']);
    expect(find.byType(LockScreenPlayerScreen), findsOneWidget);
    expect(find.text('Library'), findsNothing);

    // A cancelled or failed authentication emits no native hide event.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Library'), findsNothing);

    // The coordinator uses imperative pop after the native hidePlayer event.
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsOneWidget);
    expect(calls, ['dismiss']);
  });

  testWidgets('successful double tap keeps the player surface mounted', (
    tester,
  ) async {
    await openPlayer(tester);

    await tester.tapAt(const Offset(20, 100));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(calls, ['lockScreen']);
    expect(find.byType(LockScreenPlayerScreen), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });
}
