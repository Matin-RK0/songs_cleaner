import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/services/library_query.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_sort.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/animated_song_list.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/song_list_scroll.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/song_tile.dart';

void main() {
  final songs = List.generate(
    1000,
    (id) => Song(
      id: id,
      title: 'Song ${id.toString().padLeft(4, '0')}',
      artist: 'Artist ${1000 - id}',
      album: 'Album ${id % 13}',
      albumId: 0,
      artistId: 0,
      duration: Duration(seconds: id),
      path: '',
      sizeBytes: id,
      dateAddedSeconds: id,
      trackNumber: id,
    ),
  );

  Future<void> mountList(
    WidgetTester tester,
    ScrollController controller,
    List<Song> visibleSongs,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedSongList(
            songs: visibleSongs,
            controller: controller,
            itemExtent: SongTile.itemExtent,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, song) => Text(song.title),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final sort in SongSort.values) {
    testWidgets('locates a search result in the library ordered by $sort', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final visibleSongs = filterAndSortSongs(songs, query: '', sort: sort);
      final searchResults = filterAndSortSongs(
        songs,
        query: 'Song 0500',
        sort: SongSort.titleAsc,
      );
      final currentSong = searchResults.single;
      await mountList(tester, controller, visibleSongs);

      scrollToSong(
        controller: controller,
        songs: visibleSongs,
        songId: currentSong.id,
        reduceMotion: false,
      );
      await tester.pumpAndSettle();

      final row = find.text(currentSong.title);
      expect(row, findsOneWidget);
      expect(
        tester.getTopLeft(row).dy,
        closeTo(tester.getTopLeft(find.byType(AnimatedSongList)).dy, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses the updated order and supports reduced motion', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await mountList(tester, controller, songs);
    final reordered = songs.reversed.toList();
    await mountList(tester, controller, reordered);

    scrollToSong(
      controller: controller,
      songs: reordered,
      songId: 700,
      reduceMotion: true,
    );
    expect(controller.offset, 299 * SongTile.itemExtent);
    await tester.pump();
    expect(find.text('Song 0700'), findsOneWidget);
  });

  testWidgets(
    'clamps the last row and ignores songs outside the visible list',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await mountList(tester, controller, songs);
      scrollToSong(
        controller: controller,
        songs: songs,
        songId: songs.last.id,
        reduceMotion: true,
      );
      await tester.pump();
      expect(controller.offset, controller.position.maxScrollExtent);
      expect(find.text(songs.last.title), findsOneWidget);

      final offset = controller.offset;
      scrollToSong(
        controller: controller,
        songs: songs,
        songId: -1,
        reduceMotion: true,
      );
      expect(controller.offset, offset);
    },
  );
}
