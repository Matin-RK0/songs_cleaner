import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../domain/repositories/library_stats_repository.dart';
import '../../domain/value_objects/library_stats.dart';
import '../../infrastructure/repositories/library_stats_repository_impl.dart';

final libraryStatsRepositoryProvider = Provider<LibraryStatsRepository>(
  (ref) => LibraryStatsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

/// Favorites and play counts. Loads synchronously from local storage, so the
/// state is always available without an async loading phase.
final libraryStatsProvider =
    NotifierProvider<LibraryStatsController, LibraryStats>(
      LibraryStatsController.new,
    );

class LibraryStatsController extends Notifier<LibraryStats> {
  @override
  LibraryStats build() => ref.watch(libraryStatsRepositoryProvider).load();

  Future<void> toggleFavorite(int songId) async {
    final favorites = <int>{...state.favoriteIds};
    if (!favorites.remove(songId)) favorites.add(songId);
    state = state.copyWith(favoriteIds: favorites);
    await ref.read(libraryStatsRepositoryProvider).saveFavorites(favorites);
  }

  Future<void> addFavorites(Iterable<int> songIds) async {
    final favorites = <int>{...state.favoriteIds, ...songIds};
    state = state.copyWith(favoriteIds: favorites);
    await ref.read(libraryStatsRepositoryProvider).saveFavorites(favorites);
  }

  Future<void> recordPlay(int songId) async {
    final counts = <int, int>{...state.playCounts};
    counts[songId] = (counts[songId] ?? 0) + 1;
    state = state.copyWith(playCounts: counts);
    await ref.read(libraryStatsRepositoryProvider).savePlayCounts(counts);
  }
}
