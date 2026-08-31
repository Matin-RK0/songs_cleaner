import 'dart:convert';

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
    this.tracks = const [],
    this.currentSongId,
  });

  final List<int> queueSongIds;
  final int? currentSongId;
  final int positionMs;
  final int repeatModeIndex;
  final bool shuffled;
  /// A small metadata snapshot lets the background service rebuild its queue
  /// after Android recreates the process (before the Flutter UI/library loads).
  final List<SavedPlaybackTrack> tracks;

  /// Nothing restorable: no queue or the current track is missing.
  bool get isRestorable => queueSongIds.isNotEmpty && currentSongId != null;
}

class SavedPlaybackTrack {
  const SavedPlaybackTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.path,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String path;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'durationMs': durationMs,
        'path': path,
      };

  static SavedPlaybackTrack? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final title = value['title'];
    final artist = value['artist'];
    final album = value['album'];
    final durationMs = value['durationMs'];
    final path = value['path'];
    if (id is! num || title is! String || artist is! String ||
        album is! String || durationMs is! num || path is! String) {
      return null;
    }
    return SavedPlaybackTrack(
      id: id.toInt(),
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs.toInt(),
      path: path,
    );
  }
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
  static const String _sessionTracksKey = 'playback.session.tracks';

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
    final tracks = <SavedPlaybackTrack>[];
    final rawTracks = _prefs.getString(_sessionTracksKey);
    if (rawTracks != null) {
      try {
        final decoded = jsonDecode(rawTracks);
        if (decoded is List) {
          for (final item in decoded) {
            final track = SavedPlaybackTrack.fromJson(item);
            if (track != null && track.path.isNotEmpty) tracks.add(track);
          }
        }
      } on FormatException {
        // Ignore a corrupt optional snapshot; the id-based session remains.
      }
    }
    return SavedPlaybackSession(
      queueSongIds: ids,
      currentSongId: _prefs.getInt(_sessionCurrentKey),
      positionMs: _prefs.getInt(_sessionPositionKey) ?? 0,
      repeatModeIndex: _prefs.getInt(_sessionRepeatKey) ?? 0,
      shuffled: _prefs.getBool(_sessionShuffleKey) ?? false,
      tracks: List.unmodifiable(tracks),
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
      _prefs.setString(
        _sessionTracksKey,
        jsonEncode(session.tracks.map((track) => track.toJson()).toList()),
      ),
    ]);
  }

  Future<void> clearPlaybackSession() async {
    await Future.wait(<Future<void>>[
      _prefs.remove(_sessionQueueKey),
      _prefs.remove(_sessionCurrentKey),
      _prefs.remove(_sessionPositionKey),
      _prefs.remove(_sessionRepeatKey),
      _prefs.remove(_sessionShuffleKey),
      _prefs.remove(_sessionTracksKey),
    ]);
  }
}
