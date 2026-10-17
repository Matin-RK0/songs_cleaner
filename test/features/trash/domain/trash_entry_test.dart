import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/trash/domain/entities/trash_entry.dart';

void main() {
  test('TrashEntry round-trips through JSON', () {
    final entry = TrashEntry(
      id: '7_123',
      songId: 7,
      title: 'Track',
      artist: 'Artist',
      originalPath: '/music/track.mp3',
      trashPath: '/music/.songs_cleaner_trash/7_123',
      deletedAt: DateTime.fromMillisecondsSinceEpoch(123456),
      sizeBytes: 42,
    );

    final restored = TrashEntry.fromJson(entry.toJson());

    expect(restored?.id, entry.id);
    expect(restored?.songId, entry.songId);
    expect(restored?.originalPath, entry.originalPath);
    expect(restored?.deletedAt, entry.deletedAt);
  });

  test('TrashEntry rejects malformed JSON', () {
    expect(TrashEntry.fromJson({'id': 'missing-fields'}), isNull);
  });
}
