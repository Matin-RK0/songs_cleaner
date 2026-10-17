import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/trash_entry.dart';

class TrashRepository {
  TrashRepository(this._preferences);

  static const _key = 'fileManager.trash.v1';
  final SharedPreferences _preferences;

  List<TrashEntry> load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return List.unmodifiable(
        decoded.map(TrashEntry.fromJson).whereType<TrashEntry>(),
      );
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<TrashEntry> entries) => _preferences.setString(
    _key,
    jsonEncode(entries.map((entry) => entry.toJson()).toList()),
  );
}
