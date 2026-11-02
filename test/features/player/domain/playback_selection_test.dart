import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/domain/playback_selection.dart';

Song song(int id, {String? path}) => Song(
  id: id,
  title: 'Track $id',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: const Duration(seconds: 60),
  path: path ?? '/$id.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

void main() {
  test('history preserves first-occurrence order without duplicate tracks', () {
    final selection = PlaybackSelection([
      song(3),
      song(1),
      song(3),
      song(2),
      song(1),
    ], selected: song(2));
    expect(selection.songs.map((item) => item.id), [3, 1, 2]);
    expect(selection.startIndex, 2);
  });

  test('single search hit selects inside the complete library context', () {
    final selection = PlaybackSelection([
      song(1),
      song(2),
      song(3),
    ], selected: song(2));
    expect(selection.songs.length, 3);
    expect(selection.startIndex, 1);
  });

  test('different IDs for the same file never duplicate playback', () {
    final selection = PlaybackSelection([
      song(1),
      song(-5, path: '/1.mp3'),
      song(2),
    ], selected: song(-5, path: '/1.mp3'));
    expect(selection.songs.map((item) => item.id), [1, 2]);
    expect(selection.startIndex, 0);
  });

  test('a newly published file is included even before the library scan', () {
    final selection = PlaybackSelection([song(1), song(2)], selected: song(-5));
    expect(selection.songs.map((item) => item.id), [-5, 1, 2]);
    expect(selection.startIndex, 0);
  });

  test('an empty library legitimately yields a single playable song', () {
    final selection = PlaybackSelection([], selected: song(1));
    expect(selection.songs.single.id, 1);
    expect(selection.startIndex, 0);
  });
}
