import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/artwork_ambient_background.dart';

void main() {
  testWidgets(
    'lights move without layout changes and stop when hidden or motion is reduced',
    (tester) async {
      final enabled = ValueNotifier(true);
      final reducedMotion = ValueNotifier(false);
      addTearDown(enabled.dispose);
      addTearDown(reducedMotion.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => ValueListenableBuilder<bool>(
              valueListenable: reducedMotion,
              child: child,
              builder: (context, reduced, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduced),
                child: ValueListenableBuilder<bool>(
                  valueListenable: enabled,
                  child: child,
                  builder: (_, active, child) =>
                      TickerMode(enabled: active, child: child!),
                ),
              ),
            ),
            home: const Scaffold(
              body: ClipRect(
                child: ArtworkAmbientBackground(
                  songId: null,
                  visible: true,
                  child: SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final lights = find.descendant(
        of: find.byType(ArtworkAmbientBackground),
        matching: find.byType(Transform),
      );
      expect(lights, findsNWidgets(3));
      List<List<double>> transforms() => tester
          .widgetList<Transform>(lights)
          .map((widget) => widget.transform.storage.toList())
          .toList();
      final initial = transforms();
      await tester.pump(const Duration(seconds: 1));
      expect(transforms(), isNot(equals(initial)));
      enabled.value = false;
      await tester.pump();
      final stopped = transforms();
      await tester.pump(const Duration(seconds: 1));
      expect(transforms(), equals(stopped));
      expect(tester.binding.hasScheduledFrame, isFalse);

      reducedMotion.value = true;
      enabled.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
