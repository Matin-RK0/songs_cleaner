import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/domain/playback_enums.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/seek_bar.dart';

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
