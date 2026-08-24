import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Primitive snapshot of the last playback session. Lives in core so the
/// storage layer stays independent of feature models; player code translates
/// ids/enums.
class SavedPlaybackSession {
  const SavedPlaybackSession({
    required this.queueSongIds,
    required this.positionMs,
    required this.repeatModeIndex,
    required this.shuffled,
    this.currentSongId,
  });

  final List<int> queueSongIds;
  final int? currentSongId;
  final int positionMs;
  final int repeatModeIndex;
  final bool shuffled;

  /// Nothing restorable: no queue or the current track is missing.
  bool get isRestorable => queueSongIds.isNotEmpty && currentSongId != null;
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('Override sharedPreferencesProvider in main'),
);

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Single gateway to persistent app settings. Stores primitives only and owns
/// every key, so feature layers never touch raw preference strings.
class AppSettingsRepository {
  AppSettingsRepository(this._prefs);

  static const String _librarySortKey = 'library.sortIndex';
  static const String _homeTabIndexKey = 'home.tabIndex';
  static const String _sessionQueueKey = 'playback.session.queueIds';
  static const String _sessionCurrentKey = 'playback.session.currentId';
  static const String _sessionPositionKey = 'playback.session.positionMs';
  static const String _sessionRepeatKey = 'playback.session.repeatIndex';
  static const String _sessionShuffleKey = 'playback.session.shuffled';

  final SharedPreferences _prefs;

  // -- Library sort -----------------------------------------------------------

  int loadLibrarySortIndex(int fallback) =>
      _prefs.getInt(_librarySortKey) ?? fallback;

  Future<void> saveLibrarySortIndex(int index) =>
      _prefs.setInt(_librarySortKey, index);

  // -- Home tab ---------------------------------------------------------------

  int loadHomeTabIndex(int fallback) =>
      _prefs.getInt(_homeTabIndexKey) ?? fallback;

  Future<void> saveHomeTabIndex(int index) =>
      _prefs.setInt(_homeTabIndexKey, index);

  // -- Playback session -------------------------------------------------------

  SavedPlaybackSession? loadPlaybackSession() {
    final rawIds = _prefs.getStringList(_sessionQueueKey);
    if (rawIds == null || rawIds.isEmpty) return null;
    final ids = rawIds
        .map((raw) => int.tryParse(raw))
        .whereType<int>()
        .toList(growable: false);
    if (ids.isEmpty) return null;
    return SavedPlaybackSession(
      queueSongIds: ids,
      currentSongId: _prefs.getInt(_sessionCurrentKey),
      positionMs: _prefs.getInt(_sessionPositionKey) ?? 0,
      repeatModeIndex: _prefs.getInt(_sessionRepeatKey) ?? 0,
      shuffled: _prefs.getBool(_sessionShuffleKey) ?? false,
    );
  }

  Future<void> savePlaybackSession(SavedPlaybackSession session) async {
    await Future.wait(<Future<void>>[
      _prefs.setStringList(
        _sessionQueueKey,
        session.queueSongIds.map((id) => id.toString()).toList(growable: false),
      ),
      if (session.currentSongId != null)
        _prefs.setInt(_sessionCurrentKey, session.currentSongId!)
      else
        _prefs.remove(_sessionCurrentKey),
      _prefs.setInt(_sessionPositionKey, session.positionMs),
      _prefs.setInt(_sessionRepeatKey, session.repeatModeIndex),
      _prefs.setBool(_sessionShuffleKey, session.shuffled),
    ]);
  }

  Future<void> clearPlaybackSession() async {
    await Future.wait(<Future<void>>[
      _prefs.remove(_sessionQueueKey),
      _prefs.remove(_sessionCurrentKey),
      _prefs.remove(_sessionPositionKey),
      _prefs.remove(_sessionRepeatKey),
      _prefs.remove(_sessionShuffleKey),
    ]);
  }
}
