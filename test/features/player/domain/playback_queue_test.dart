import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/domain/playback_queue.dart';

void main() {
  Song song(int id) => Song(
    id: id,
    title: 'Song $id',
    artist: 'Artist',
    album: 'Album',
    albumId: 0,
    artistId: 0,
    duration: const Duration(seconds: 180),
    path: '/music/s$id.mp3',
    sizeBytes: 0,
    dateAddedSeconds: 0,
  );

  group('load', () {
    test('loads songs and points at startIndex', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3)], startIndex: 1);
      expect(queue.current?.id, 2);
      expect(queue.originalSongs.map((s) => s.id), [1, 2, 3]);
      expect(queue.songs.map((s) => s.id), [1, 2, 3]);
    });
  });

  group('restore order (shuffle keeps current first)', () {
    test(
      'enabling shuffle keeps the playing song first and shuffles the rest',
      () {
        final queue = PlaybackQueue()
          ..load([song(1), song(2), song(3), song(4)], startIndex: 2);
        queue.setShuffled(true);
        expect(queue.shuffled, isTrue);
        expect(queue.current?.id, 3);
        expect(queue.songs.first.id, 3);
        expect(queue.songs.take(1).map((s) => s.id), [3]);
        // The remaining songs are the other three, in some order.
        expect(queue.songs.skip(1).map((s) => s.id).toSet(), {1, 2, 4});
      },
    );

    test('disabling shuffle restores the original order at the same song', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3), song(4)], startIndex: 0);
      queue.setShuffled(true);
      queue.setShuffled(false);
      expect(queue.shuffled, isFalse);
      expect(queue.songs.map((s) => s.id), [1, 2, 3, 4]);
    });
  });

  group('navigation', () {
    test(
      'metadata refresh preserves shuffle order, selection and missing tracks',
      () {
        final queue = PlaybackQueue()
          ..load([song(1), song(2), song(3)], startIndex: 1)
          ..setShuffled(true);
        final order = queue.songs.map((song) => song.id).toList();
        final updated = song(2);

        queue.refreshMetadata([updated]);

        expect(queue.current, same(updated));
        expect(queue.shuffled, isTrue);
        expect(queue.songs.map((song) => song.id), order);
        expect(queue.originalSongs.map((song) => song.id), [1, 2, 3]);
        queue.setShuffled(false);
        expect(queue.current, same(updated));
      },
    );

    test('next advances and wraps when requested', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3)], startIndex: 2);
      expect(queue.next(), isFalse); // at the end, no wrap
      expect(queue.next(wrap: true), isTrue);
      expect(queue.current?.id, 1);
    });

    test('previous seeks to the previous track; respects wrap', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3)], startIndex: 0);
      expect(queue.previous(wrap: true), isTrue);
      expect(queue.current?.id, 3);
    });
  });

  group('removal', () {
    test('removing a song before the current index shifts it back', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3)], startIndex: 2);
      queue.removeById(1);
      expect(queue.songs.map((s) => s.id), [2, 3]);
      expect(queue.current?.id, 3);
    });

    test('removing the last song clears an empty queue', () {
      final queue = PlaybackQueue()..load([song(1)], startIndex: 0);
      queue.removeById(1);
      expect(queue.isNotEmpty, isFalse);
      expect(queue.current, isNull);
    });
  });

  group('manual queue editing', () {
    test('adds a new song to the end but rejects duplicates', () {
      final queue = PlaybackQueue()..load([song(1), song(2)]);

      expect(queue.addToEnd(song(3)), isTrue);
      expect(queue.addToEnd(song(2)), isFalse);
      expect(queue.songs.map((item) => item.id), [1, 2, 3]);
    });

    test('moves an existing song directly after the current song', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3), song(4)], startIndex: 1);

      expect(queue.playNext(song(4)), isTrue);
      expect(queue.songs.map((item) => item.id), [1, 2, 4, 3]);
      expect(queue.current?.id, 2);
    });

    test('inserts an external song after the current song', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3)], startIndex: 1);

      expect(queue.playNext(song(9)), isTrue);
      expect(queue.songs.map((item) => item.id), [1, 2, 9, 3]);
      expect(queue.current?.id, 2);
    });

    test('reorder preserves the current song identity', () {
      final queue = PlaybackQueue()
        ..load([song(1), song(2), song(3), song(4)], startIndex: 2);

      expect(queue.reorder(0, 3), isTrue);
      expect(queue.songs.map((item) => item.id), [2, 3, 4, 1]);
      expect(queue.current?.id, 3);
      expect(queue.currentIndex, 1);
    });
  });
}
