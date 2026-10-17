import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/playlists/application/playlist_transfer_service.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/playlist.dart';

void main() {
  const service = PlaylistTransferService();
  final song = Song(
    id: 4,
    title: 'Track',
    artist: 'Artist',
    album: 'Album',
    albumId: 1,
    artistId: 2,
    duration: Duration(minutes: 3),
    path: '/music/track.mp3',
    sizeBytes: 100,
    dateAddedSeconds: 1,
  );
  final playlist = Playlist(
    id: 'playlist',
    name: 'Favorites',
    songIds: const [4],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('exports portable song paths and imports them', () {
    final content = service.encode([playlist], [song]);
    final imported = service.decode(content);

    expect(imported.single.name, 'Favorites');
    expect(imported.single.songPaths, ['/music/track.mp3']);
  });

  test('rejects unsupported playlist files', () {
    expect(() => service.decode('{"version": 1}'), throwsFormatException);
  });
}
