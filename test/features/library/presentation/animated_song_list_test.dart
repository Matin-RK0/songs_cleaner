import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/theme/app_motion.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/animated_song_list.dart';

Song song(int id) => Song(
  id: id,
  title: 'Song $id',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration.zero,
  path: '',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

Widget host(List<Song> songs, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: AnimatedSongList(
        songs: songs,
        itemExtent: 80,
        physics: const ClampingScrollPhysics(),
        emptyState: const Text('Empty'),
        itemBuilder: (_, song) => Text(song.title),
      ),
    ),
  ),
);

void main() {
  testWidgets('removes the last row before presenting the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(host([song(1)]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host([]));
    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Empty'), findsNothing);
    await tester.pump(AppMotion.fast);
    await tester.pumpAndSettle();
    expect(find.text('Song 1'), findsNothing);
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('coalesces updates received during removal to the newest list', (
    tester,
  ) async {
    await tester.pumpWidget(host([song(1), song(2), song(3)]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host([song(2), song(3)]));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(host([song(4), song(3)]));
    await tester.pumpAndSettle();
    expect(find.text('Song 1'), findsNothing);
    expect(find.text('Song 2'), findsNothing);
    expect(find.text('Song 3'), findsOneWidget);
    expect(find.text('Song 4'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Song 4')).dy,
      lessThan(tester.getTopLeft(find.text('Song 3')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects reduced motion and keeps large libraries lazy', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(List.generate(1000, song), reduceMotion: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.text('Song 999'), findsNothing);
    await tester.pumpWidget(host([], reduceMotion: true));
    await tester.pump();
    expect(find.text('Empty'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
