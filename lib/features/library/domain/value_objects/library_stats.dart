/// Immutable snapshot of the user's library signals that power favorites and
/// the "most played" smart playlist. Pure domain data with no Flutter or
/// storage dependencies.
class LibraryStats {
  const LibraryStats({
    this.favoriteIds = const <int>{},
    this.playCounts = const <int, int>{},
  });

  final Set<int> favoriteIds;
  final Map<int, int> playCounts;

  static const LibraryStats empty = LibraryStats();

  bool isFavorite(int songId) => favoriteIds.contains(songId);

  int playCount(int songId) => playCounts[songId] ?? 0;

  LibraryStats copyWith({Set<int>? favoriteIds, Map<int, int>? playCounts}) {
    return LibraryStats(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      playCounts: playCounts ?? this.playCounts,
    );
  }
}
