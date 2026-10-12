import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/playlists/presentation/widgets/playlist_card.dart';

void main() {
  testWidgets('renders title and subtitle and forwards taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: PlaylistCard(
                title: 'My Mix',
                subtitle: '3 songs',
                cover: const ColoredBox(color: Color(0xFF2196F3)),
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('My Mix'), findsOneWidget);
    expect(find.text('3 songs'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });
}
