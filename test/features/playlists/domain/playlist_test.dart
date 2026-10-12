import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/playlist.dart';

void main() {
  Playlist build({List<int>? songIds}) => Playlist(
    id: 'p1',
    name: 'Mix',
    songIds: songIds ?? const [1, 2, 3],
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
  );

  group('Playlist', () {
    test('reports count, emptiness and membership', () {
      expect(build().songCount, 3);
      expect(build(songIds: const []).isEmpty, isTrue);
      expect(build().contains(2), isTrue);
      expect(build().contains(9), isFalse);
    });

    test('copyWith updates name, songs and updatedAt but keeps identity', () {
      final playlist = build();
      final updated = playlist.copyWith(
        name: 'Chill',
        songIds: const [3, 1],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(5000),
      );

      expect(updated.id, playlist.id);
      expect(updated.createdAt, playlist.createdAt);
      expect(updated.name, 'Chill');
      expect(updated.songIds, const [3, 1]);
      expect(updated.updatedAt.millisecondsSinceEpoch, 5000);
      expect(playlist.name, 'Mix');
    });

    test('copyWith keeps existing values when arguments are omitted', () {
      final playlist = build();
      final same = playlist.copyWith();

      expect(same.name, playlist.name);
      expect(same.songIds, playlist.songIds);
      expect(same.updatedAt, playlist.updatedAt);
    });

    test('serializes and restores through JSON', () {
      final playlist = build();
      final restored = Playlist.fromJson(playlist.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, playlist.id);
      expect(restored.name, playlist.name);
      expect(restored.songIds, playlist.songIds);
      expect(restored.createdAt, playlist.createdAt);
      expect(restored.updatedAt, playlist.updatedAt);
    });

    test('fromJson returns null for malformed input', () {
      expect(Playlist.fromJson(null), isNull);
      expect(Playlist.fromJson('nope'), isNull);
      expect(Playlist.fromJson(<Object?, Object?>{}), isNull);
      expect(
        Playlist.fromJson(<Object?, Object?>{
          'id': 'p1',
          'name': 'Mix',
          'songIds': 'not-a-list',
        }),
        isNull,
      );
    });

    test('equality is based on id', () {
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });
  });
}
