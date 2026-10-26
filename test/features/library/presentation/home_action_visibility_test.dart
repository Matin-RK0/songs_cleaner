import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/theme/app_motion.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/home_action_visibility.dart';

void main() {
  Widget action({required bool visible, bool reduceMotion = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: HomeActionVisibility(
          visible: visible,
          child: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.shuffle_rounded),
          ),
        ),
      ),
    );
  }

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(HomeActionVisibility),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('lays out entry at zero opacity then fades in and out', (
    tester,
  ) async {
    await tester.pumpWidget(action(visible: false));
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.pumpWidget(action(visible: true));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(opacity(tester), 0);

    await tester.pump();
    await tester.pump(AppMotion.normal ~/ 2);
    expect(opacity(tester), greaterThan(0));
    expect(opacity(tester), lessThan(1));
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);

    await tester.pumpWidget(action(visible: false));
    await tester.pump(AppMotion.normal ~/ 2);
    expect(opacity(tester), greaterThan(0));
    expect(opacity(tester), lessThan(1));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('rapid tab changes settle to the latest visibility', (
    tester,
  ) async {
    await tester.pumpWidget(action(visible: false));
    await tester.pumpWidget(action(visible: true));
    await tester.pumpWidget(action(visible: false));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.pumpWidget(action(visible: true));
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('reduced motion updates visibility immediately', (tester) async {
    await tester.pumpWidget(action(visible: false, reduceMotion: true));
    await tester.pumpWidget(action(visible: true, reduceMotion: true));
    expect(opacity(tester), 1);
    await tester.pumpWidget(action(visible: false, reduceMotion: true));
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
