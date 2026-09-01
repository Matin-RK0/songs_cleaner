import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/application/session_resume.dart';
import 'package:songs_cleaner/features/player/domain/playback_enums.dart';

void main() {
  Song song(int id, {String path = '/music/s.mp3'}) => Song(
        id: id,
        title: 'Song $id',
        artist: 'Artist',
        album: 'Album',
        albumId: 0,
        artistId: 0,
        duration: const Duration(seconds: 180),
        path: path,
        sizeBytes: 0,
        dateAddedSeconds: 0,
      );

  SavedPlaybackSession session({
    List<int> queueIds = const [1, 2, 3],
    int? currentId = 2,
    int positionMs = 45000,
    int repeatIndex = 0,
    bool shuffled = false,
  }) =>
      SavedPlaybackSession(
        queueSongIds: queueIds,
        currentSongId: currentId,
        positionMs: positionMs,
        repeatModeIndex: repeatIndex,
        shuffled: shuffled,
      );

  test('returns a plan for a valid restorable session', () {
    final library = [song(1), song(2), song(3), song(4)];
    final plan = SessionResumePlanner.plan(session(), library);

    expect(plan, isNotNull);
    expect(plan!.queue.map((s) => s.id), [1, 2, 3]);
    expect(plan.current.id, 2);
    expect(plan.position, const Duration(milliseconds: 45000));
    expect(plan.repeatMode, RepeatMode.off);
    expect(plan.shuffled, isFalse);
  });

  test('returns null when there is no session', () {
    expect(SessionResumePlanner.plan(null, <Song>[]), isNull);
  });

  test('returns null when the current track is missing from the library', () {
    final plan = SessionResumePlanner.plan(session(), <Song>[song(1), song(3)]);
    expect(plan, isNull);
  });

  test('returns null when the queue is empty', () {
    final plan = SessionResumePlanner.plan(
      session(queueIds: const [], currentId: null),
      <Song>[song(1)],
    );
    expect(plan, isNull);
  });

  test('drops queued ids that are no longer in the library but keeps the plan',
      () {
    final plan = SessionResumePlanner.plan(
      session(queueIds: const [1, 2, 3, 9], currentId: 1),
      [song(1), song(2), song(3)],
    );
    expect(plan, isNotNull);
    expect(plan!.queue.map((s) => s.id), [1, 2, 3]);
    expect(plan.current.id, 1);
  });

  test('clamps an out-of-range repeat index', () {
    final plan = SessionResumePlanner.plan(
      session(repeatIndex: 99),
      [song(1), song(2), song(3)],
    );
    expect(plan!.repeatMode, RepeatMode.one);
  });

  test('maps repeat mode and shuffle flags', () {
    final plan = SessionResumePlanner.plan(
      session(repeatIndex: 1, shuffled: true),
      [song(1), song(2), song(3)],
    );
    expect(plan!.repeatMode, RepeatMode.all);
    expect(plan.shuffled, isTrue);
  });
}
