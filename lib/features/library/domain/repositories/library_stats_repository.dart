import '../value_objects/library_stats.dart';

/// Persistence contract for favorites and play counts. Implemented in the
/// infrastructure layer so the domain and UI never touch storage directly.
abstract interface class LibraryStatsRepository {
  LibraryStats load();

  Future<void> saveFavorites(Set<int> favoriteIds);

  Future<void> savePlayCounts(Map<int, int> playCounts);
}
