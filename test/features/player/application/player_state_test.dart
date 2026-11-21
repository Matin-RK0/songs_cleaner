import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/domain/playback_enums.dart';

void main() {
  const song = Song(
    id: 1,
    title: 'Track',
    artist: '',
    album: '',
    albumId: 0,
    artistId: 0,
    duration: Duration(minutes: 1),
    path: '/track.mp3',
    sizeBytes: 0,
    dateAddedSeconds: 0,
  );
  const ready = PlayerState(
    songs: [song],
    index: 0,
    playing: true,
    processingState: PlayerProcessingState.ready,
  );

  test('an empty or paused player has no active playback', () {
    expect(ready.copyWith(index: -1).hasActivePlayback, isFalse);
    expect(ready.copyWith(playing: false).hasActivePlayback, isFalse);
  });

  test('terminal decoder states are inactive even with the play flag set', () {
    for (final state in [
      PlayerProcessingState.idle,
      PlayerProcessingState.completed,
    ]) {
      expect(ready.copyWith(processingState: state).hasActivePlayback, isFalse);
    }
  });

  test('active playback stays active when buffering between audio frames', () {
    expect(ready.hasActivePlayback, isTrue);
    expect(
      ready
          .copyWith(processingState: PlayerProcessingState.buffering)
          .hasActivePlayback,
      isTrue,
    );
  });
}
