import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_icon.dart';

void main() {
  testWidgets('cached rounded glyphs repaint after hot reload', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IconTheme(
            data: IconThemeData(size: 32, color: Colors.blue),
            child: PlayerIcon(PlayerGlyph.play),
          ),
        ),
      ),
    );
    final paint = find.descendant(
      of: find.byType(PlayerIcon),
      matching: find.byType(CustomPaint),
    );
    final previous = tester.widget<CustomPaint>(paint).painter!;
    expect(previous.shouldRepaint(previous), isFalse);
    // Reassemble waits for a frame; drive the fake clock before awaiting it.
    final reassemble = tester.binding.reassembleApplication();
    await tester.pumpAndSettle();
    await reassemble;
    final refreshed = tester.widget<CustomPaint>(paint).painter!;
    expect(refreshed.shouldRepaint(previous), isTrue);
    expect(tester.takeException(), isNull);
  });
}
