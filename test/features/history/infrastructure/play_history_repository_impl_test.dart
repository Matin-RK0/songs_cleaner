import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/features/history/domain/entities/play_history_entry.dart';
import 'package:songs_cleaner/features/history/infrastructure/repositories/play_history_repository_impl.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips history entries and clears them', () async {
    final repository = PlayHistoryRepositoryImpl(
      await SharedPreferences.getInstance(),
    );
    final entries = [
      PlayHistoryEntry(songId: 4, playedAt: DateTime(2026, 10, 17, 12)),
      PlayHistoryEntry(songId: 8, playedAt: DateTime(2026, 10, 16, 9)),
    ];

    await repository.save(entries);
    final restored = repository.load();

    expect(restored.map((entry) => entry.songId), [4, 8]);
    expect(restored.first.playedAt, entries.first.playedAt);

    await repository.clear();
    expect(repository.load(), isEmpty);
  });

  test('returns an empty list for corrupt storage', () async {
    SharedPreferences.setMockInitialValues({
      'library.playHistory.v1': '{invalid',
    });
    final repository = PlayHistoryRepositoryImpl(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load(), isEmpty);
  });
}
