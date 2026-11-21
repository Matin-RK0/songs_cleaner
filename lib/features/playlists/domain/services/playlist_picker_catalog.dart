import '../../../library/domain/entities/song.dart';
import '../../../library/domain/value_objects/song_sort.dart';

enum PlaylistPickerTab { tracks, albums, artists, folders }

typedef PlaylistPickerEntry = ({
  String key,
  String title,
  Song cover,
  List<int> ids,
});

List<PlaylistPickerEntry> buildPlaylistPickerCatalog(
  List<Song> library,
  List<int> existingIds,
  PlaylistPickerTab tab,
) {
  final existing = existingIds.toSet();
  final available =
      library.where((song) => !existing.contains(song.id)).toList()
        ..sort(SongSort.titleAsc.compare);
  if (tab == PlaylistPickerTab.tracks) {
    return [
      for (final song in available)
        (key: '${song.id}', title: song.title, cover: song, ids: [song.id]),
    ];
  }
  final groups = <String, PlaylistPickerEntry>{};
  for (final song in available) {
    final (key, title) = switch (tab) {
      PlaylistPickerTab.albums => (
        song.albumId > 0 ? '${song.albumId}' : song.album.toLowerCase(),
        song.album,
      ),
      PlaylistPickerTab.artists => (
        song.artistId > 0 ? '${song.artistId}' : song.artist.toLowerCase(),
        song.artist,
      ),
      PlaylistPickerTab.folders => (song.folderPath, song.folderName),
      PlaylistPickerTab.tracks => throw StateError('Tracks are not grouped'),
    };
    groups
        .putIfAbsent(key, () => (key: key, title: title, cover: song, ids: []))
        .ids
        .add(song.id);
  }
  return groups.values.toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
}

List<PlaylistPickerEntry> filterPlaylistPickerCatalog(
  List<PlaylistPickerEntry> entries,
  PlaylistPickerTab tab,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return entries;
  return entries
      .where(
        (entry) =>
            entry.title.toLowerCase().contains(needle) ||
            (tab == PlaylistPickerTab.tracks &&
                (entry.cover.artist.toLowerCase().contains(needle) ||
                    entry.cover.album.toLowerCase().contains(needle))) ||
            (tab == PlaylistPickerTab.folders &&
                entry.key.toLowerCase().contains(needle)),
      )
      .toList(growable: false);
}
