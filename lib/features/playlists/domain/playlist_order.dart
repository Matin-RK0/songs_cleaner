import 'entities/playlist.dart';

export 'playlist_track_order.dart';

enum PlaylistListOrder {
  name,
  updated,
  trackCount,
  favorites;

  static PlaylistListOrder restore(String value) =>
      values.firstWhere((order) => order.name == value, orElse: () => name);

  List<Playlist> apply(List<Playlist> playlists) => List.unmodifiable(
    [...playlists]..sort((a, b) {
      final order = switch (this) {
        name => 0,
        updated => b.updatedAt.compareTo(a.updatedAt),
        trackCount => b.songCount.compareTo(a.songCount),
        favorites => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0),
      };
      if (order != 0) return order;
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return byName == 0 ? a.id.compareTo(b.id) : byName;
    }),
  );
}
