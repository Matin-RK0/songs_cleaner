import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/history/domain/entities/play_history_entry.dart';
import 'package:songs_cleaner/features/history/domain/services/play_history_policy.dart';

void main() {
  PlayHistoryEntry entry(int id) => PlayHistoryEntry(
    songId: id,
    playedAt: DateTime.fromMillisecondsSinceEpoch(id * 1000),
  );

  test('record puts the newest event first', () {
    final result = PlayHistoryPolicy.record([entry(1), entry(2)], entry(3));

    expect(result.map((item) => item.songId), [3, 1, 2]);
  });

  test('record keeps only the newest 200 events', () {
    final existing = List.generate(200, entry);

    final result = PlayHistoryPolicy.record(existing, entry(999));

    expect(result, hasLength(PlayHistoryPolicy.maxEntries));
    expect(result.first.songId, 999);
    expect(result.last.songId, 198);
  });

  test('history entry rejects malformed JSON', () {
    expect(PlayHistoryEntry.fromJson({'songId': 'bad'}), isNull);
  });
}
