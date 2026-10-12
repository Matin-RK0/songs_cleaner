import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/library_stats_repository.dart';
import '../../domain/value_objects/library_stats.dart';

/// Stores favorites as a string list and play counts as a compact JSON map.
/// Reads are synchronous so the in-memory stats resolve without a loading
/// state; writes are fire-and-forget from the controller.
class LibraryStatsRepositoryImpl implements LibraryStatsRepository {
  LibraryStatsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _favoritesKey = 'library.favorites.v1';
  static const String _playCountsKey = 'library.playCounts.v1';

  @override
  LibraryStats load() {
    final favoriteIds = (_prefs.getStringList(_favoritesKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    return LibraryStats(
      favoriteIds: favoriteIds,
      playCounts: _decodePlayCounts(_prefs.getString(_playCountsKey)),
    );
  }

  @override
  Future<void> saveFavorites(Set<int> favoriteIds) async {
    await _prefs.setStringList(
      _favoritesKey,
      favoriteIds.map((id) => id.toString()).toList(growable: false),
    );
  }

  @override
  Future<void> savePlayCounts(Map<int, int> playCounts) async {
    await _prefs.setString(
      _playCountsKey,
      jsonEncode(
        playCounts.map((id, count) => MapEntry(id.toString(), count)),
      ),
    );
  }

  Map<int, int> _decodePlayCounts(String? raw) {
    if (raw == null) return const <int, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <int, int>{};
      final counts = <int, int>{};
      decoded.forEach((key, value) {
        final id = int.tryParse('$key');
        if (id != null && value is num) counts[id] = value.toInt();
      });
      return counts;
    } on FormatException {
      return const <int, int>{};
    }
  }
}
