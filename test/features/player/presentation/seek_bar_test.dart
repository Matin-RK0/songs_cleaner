import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/domain/playback_enums.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/seek_bar.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/core/theme/app_typography.dart';

class _Player extends PlayerController {
  final seekCompleted = Completer<void>();

  @override
  PlayerState build() => const PlayerState(
    duration: Duration(minutes: 5),
    position: Duration(minutes: 2),
    processingState: PlayerProcessingState.ready,
  );

  void update(PlayerState next) => state = next;

  @override
  Future<void> seek(Duration position) async {
    await seekCompleted.future;
    state = state.copyWith(position: position);
  }
}

void main() {
  for (final direction in TextDirection.values) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'thin timeline with inset small labels; $direction scale=$textScale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 180));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [playerProvider.overrideWith(_Player.new)],
              child: MaterialApp(
                theme: AppTheme.dark(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Directionality(
                    textDirection: direction,
                    child: const SeekBar(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final sliderTheme = tester.widget<SliderTheme>(
            find.descendant(
              of: find.byType(SeekBar),
              matching: find.byType(SliderTheme),
            ),
          );
          expect(sliderTheme.data.trackHeight, 2);
          expect(
            tester.getSize(find.byType(Slider)).height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.getTopLeft(find.text('2:00')).dx, 40);
          expect(tester.getTopRight(find.text('5:00')).dx, 280);
          final lineCenter = tester.getCenter(find.byType(Slider)).dy;
          expect(tester.getTopLeft(find.text('2:00')).dy - lineCenter, 12);
          for (final value in ['2:00', '5:00']) {
            final style = tester.widget<Text>(find.text(value)).style!;
            expect(style.fontSize, 11);
            expect(style.fontFamily, AppTypography.fontFamily);
            expect(
              style.fontFeatures,
              contains(const FontFeature.tabularFigures()),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'seek holds the dragged position until the player acknowledges it',
    (tester) async {
      final controller = _Player();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playerProvider.overrideWith(() => controller)],
          child: const MaterialApp(home: Scaffold(body: SeekBar())),
        ),
      );
      await tester.pumpAndSettle();

      var slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(180000);
      slider.onChangeEnd!(180000);
      await tester.pump();

      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 180000);

      controller.seekCompleted.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 180000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a duration change during dragging remains bounded', (
    tester,
  ) async {
    final controller = _Player();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: Scaffold(body: SeekBar())),
      ),
    );
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(240000);
    await tester.pump();

    controller.update(
      const PlayerState(
        duration: Duration(seconds: 30),
        processingState: PlayerProcessingState.loading,
      ),
    );
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, lessThanOrEqualTo(slider.max));
    expect(slider.onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
}
