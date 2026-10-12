/// The automatic, always-available playlists derived from library signals.
enum SmartPlaylistKind {
  /// Songs the user marked as favorites.
  liked,

  /// Every library song, newest first.
  recentlyAdded,

  /// Songs ordered by how many times they were played.
  mostPlayed,
}
