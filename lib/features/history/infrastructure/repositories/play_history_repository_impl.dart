import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/play_history_entry.dart';
import '../../domain/repositories/play_history_repository.dart';

class PlayHistoryRepositoryImpl implements PlayHistoryRepository {
  PlayHistoryRepositoryImpl(this._prefs);

  static const String _historyKey = 'library.playHistory.v1';

  final SharedPreferences _prefs;

  @override
  List<PlayHistoryEntry> load() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return List.unmodifiable(
        decoded.map(PlayHistoryEntry.fromJson).whereType<PlayHistoryEntry>(),
      );
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<PlayHistoryEntry> entries) async {
    await _prefs.setString(
      _historyKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() => _prefs.remove(_historyKey);
}
