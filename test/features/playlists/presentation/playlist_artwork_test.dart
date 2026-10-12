import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/playlists/presentation/widgets/playlist_artwork.dart';

void main() {
  testWidgets('shows a placeholder icon when the playlist is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: PlaylistArtwork(songIds: [], size: 120)),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
  });
}
