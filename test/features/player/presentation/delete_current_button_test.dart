import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/cleanup/application/cleanup_service.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/delete_current_button.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';

const _song = Song(
  id: 1,
  title: 'Track',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(minutes: 3),
  path: '/1.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Cleanup extends CleanupService {
  _Cleanup(super.ref);

  final result = Completer<CleanupResult>();
  int calls = 0;
  bool? usedTrash;

  @override
  Future<CleanupResult> deleteFromDevice(Song song, {bool useTrash = true}) {
    calls++;
    usedTrash = useTrash;
    return result.future;
  }
}

void main() {
  late _Cleanup cleanup;
  Future<void> open(
    WidgetTester tester, {
    ValueNotifier<bool>? showButton,
    String language = 'en',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanupServiceProvider.overrideWith((ref) => cleanup = _Cleanup(ref)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(primary: const Color(0xFFAA33CC)),
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: showButton == null
                  ? const DeleteCurrentButton(song: _song)
                  : ValueListenableBuilder<bool>(
                      valueListenable: showButton,
                      builder: (_, show, _) => show
                          ? const DeleteCurrentButton(song: _song)
                          : const Text('Next track'),
                    ),
            ),
          ),
        ),
      ),
    );
    // Construct the fake without performing a destructive action.
    final context = tester.element(find.byType(DeleteCurrentButton));
    ProviderScope.containerOf(context).read(cleanupServiceProvider);
  }

  testWidgets('tap and short hold never delete', (tester) async {
    await open(tester);
    final button = find.byType(FilledButton);
    expect(
      tester.widget<FilledButton>(button).style!.foregroundColor!.resolve({}),
      const Color(0xFFAA33CC),
    );
    final style = tester.widget<FilledButton>(button).style!;
    expect(style.backgroundColor!.resolve({}), Colors.transparent);
    expect(
      style.overlayColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(style.splashFactory, NoSplash.splashFactory);
    await tester.tap(button);
    await tester.pump();
    expect(cleanup.calls, 0);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(kLongPressTimeout - const Duration(milliseconds: 1));
    expect(cleanup.calls, 0);
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(cleanup.calls, 0);
  });

  testWidgets('standard hold deletes once and blocks repeats while pending', (
    tester,
  ) async {
    await open(tester);
    final button = find.byType(FilledButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(kLongPressTimeout - const Duration(milliseconds: 1));
    expect(cleanup.calls, 0);
    await tester.pump(const Duration(milliseconds: 2));
    expect(cleanup.calls, 1);
    expect(cleanup.usedTrash, isFalse);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    expect(cleanup.calls, 1);

    await tester.longPress(button);
    expect(cleanup.calls, 1);
    cleanup.result.complete(const CleanupSuccess(_song, null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<FilledButton>(button).onLongPress, isNotNull);
  });

  testWidgets('dragging off the button cancels deletion', (tester) async {
    await open(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    expect(cleanup.calls, 0);
  });

  testWidgets('disposing during a hold cancels deletion', (tester) async {
    await open(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    expect(cleanup.calls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final success in [true, false]) {
    testWidgets(
      'feedback survives replacing the initiating button; success: $success',
      (tester) async {
        final showButton = ValueNotifier(true);
        addTearDown(showButton.dispose);
        await open(tester, showButton: showButton);
        await tester.longPress(find.byType(FilledButton));
        expect(cleanup.calls, 1);
        showButton.value = false;
        await tester.pump();
        expect(find.byType(DeleteCurrentButton), findsNothing);
        cleanup.result.complete(
          success
              ? const CleanupSuccess(_song, null)
              : CleanupFailed(StateError('internal error')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(success ? '"Track" deleted' : 'Could not delete "Track"'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('hold fills left to right in RTL and resets on early release', (
    tester,
  ) async {
    await open(tester, language: 'fa');
    final fill = find.descendant(
      of: find.byType(DeleteCurrentButton),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Transform && widget.alignment == Alignment.centerLeft,
      ),
    );
    expect(tester.widget<Transform>(fill).transform.storage[0], 0);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    await tester.pump(kLongPressTimeout ~/ 2);
    expect(
      tester.widget<Transform>(fill).transform.storage[0],
      closeTo(0.5, 0.01),
    );
    expect(cleanup.calls, 0);
    await gesture.up();
    await tester.pump();
    expect(tester.widget<Transform>(fill).transform.storage[0], 0);
    expect(cleanup.calls, 0);
  });
}
