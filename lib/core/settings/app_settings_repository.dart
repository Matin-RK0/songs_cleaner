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
    this.wasPlaying = false,
  });

  final List<int> queueSongIds;
  final int? currentSongId;
  final int positionMs;
  final int repeatModeIndex;
  final bool shuffled;

  /// A small metadata snapshot lets the background service rebuild its queue
  /// after Android recreates the process (before the Flutter UI/library loads).
  final List<SavedPlaybackTrack> tracks;
  final bool wasPlaying;

  /// Nothing restorable: no queue or the current track is missing.
  bool get isRestorable => queueSongIds.isNotEmpty && currentSongId != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'queueSongIds': queueSongIds,
    'currentSongId': currentSongId,
    'positionMs': positionMs,
    'repeatModeIndex': repeatModeIndex,
    'shuffled': shuffled,
    'wasPlaying': wasPlaying,
    'tracks': tracks.map((track) => track.toJson()).toList(growable: false),
  };

  static SavedPlaybackSession? fromJson(Object? value) {
    if (value is! Map) return null;
    final rawIds = value['queueSongIds'];
    final currentSongId = value['currentSongId'];
    final positionMs = value['positionMs'];
    final repeatModeIndex = value['repeatModeIndex'];
    final shuffled = value['shuffled'];
    final wasPlaying = value['wasPlaying'];
    final rawTracks = value['tracks'];
    if (rawIds is! List ||
        currentSongId is! num ||
        positionMs is! num ||
        repeatModeIndex is! num ||
        shuffled is! bool) {
      return null;
    }
    final ids = rawIds.whereType<num>().map((id) => id.toInt()).toList();
    if (ids.isEmpty) return null;
    final tracks = rawTracks is List
        ? rawTracks
              .map(SavedPlaybackTrack.fromJson)
              .whereType<SavedPlaybackTrack>()
              .toList(growable: false)
        : const <SavedPlaybackTrack>[];
    return SavedPlaybackSession(
      queueSongIds: List.unmodifiable(ids),
      currentSongId: currentSongId.toInt(),
      positionMs: positionMs.toInt().clamp(0, 1 << 53).toInt(),
      repeatModeIndex: repeatModeIndex.toInt(),
      shuffled: shuffled,
      wasPlaying: wasPlaying is bool && wasPlaying,
      tracks: List.unmodifiable(tracks),
    );
  }
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
    if (id is! num ||
        title is! String ||
        artist is! String ||
        album is! String ||
        durationMs is! num ||
        path is! String) {
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
  static const String _homeTabLayoutVersionKey = 'home.tabLayoutVersion';
  static const String _sessionQueueKey = 'playback.session.queueIds';
  static const String _sessionCurrentKey = 'playback.session.currentId';
  static const String _sessionPositionKey = 'playback.session.positionMs';
  static const String _sessionRepeatKey = 'playback.session.repeatIndex';
  static const String _sessionShuffleKey = 'playback.session.shuffled';
  static const String _sessionTracksKey = 'playback.session.tracks';
  static const String _sessionSnapshotKey = 'playback.session.snapshot.v2';
  static const String _lockScreenEnabledKey = 'lockscreen.enabled';
  static const String _previousGoesToPreviousKey =
      'player.previousGoesToPrevious';
  static const String _hideQuickDeleteKey = 'player.hideQuickDelete';
  static const String _playbackSpeedKey = 'player.playbackSpeed';
  static const String _equalizerEnabledKey = 'audio.equalizer.enabled';
  static const String _equalizerGainsKey = 'audio.equalizer.gains';
  static const String _audioFocusModeKey = 'audio.focusMode';
  static const String _gaplessPlaybackKey = 'audio.gaplessPlayback';
  static const String _themeModeKey = 'appearance.themeMode';
  static const String _primaryColorIndexKey = 'appearance.primaryColorIndex';
  static const String _primaryColorArgbKey = 'appearance.primaryColorArgb';
  static const String _widgetBackgroundColorKey = 'widget.backgroundColor';
  static const String _localeKey = 'appearance.locale';

  final SharedPreferences _prefs;

  // -- Library sort -----------------------------------------------------------

  int loadLibrarySortIndex(int fallback) =>
      _prefs.getInt(_librarySortKey) ?? fallback;

  Future<void> saveLibrarySortIndex(int index) =>
      _prefs.setInt(_librarySortKey, index);

  // -- Home tab ---------------------------------------------------------------

  int loadHomeTabIndex(int fallback) {
    final stored = _prefs.getInt(_homeTabIndexKey);
    if (stored == null) return fallback;
    final layoutVersion = _prefs.getInt(_homeTabLayoutVersionKey) ?? 1;
    return layoutVersion < 2 && stored == 3 ? 5 : stored;
  }

  Future<void> saveHomeTabIndex(int index) async {
    await Future.wait([
      _prefs.setInt(_homeTabIndexKey, index),
      _prefs.setInt(_homeTabLayoutVersionKey, 2),
    ]);
  }

  // -- Lock screen ------------------------------------------------------------

  static const lockScreenTimeoutOptions = [5, 10, 15, 30, 60];
  static const _lockScreenTimeoutKey = 'lockscreen.timeoutSeconds';

  int loadLockScreenTimeoutSeconds() {
    final value = _prefs.getInt(_lockScreenTimeoutKey);
    return lockScreenTimeoutOptions.contains(value) ? value! : 5;
  }

  Future<void> saveLockScreenTimeoutSeconds(int seconds) {
    if (!lockScreenTimeoutOptions.contains(seconds)) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    return _prefs.setInt(_lockScreenTimeoutKey, seconds);
  }

  bool loadLockScreenEnabled(bool fallback) =>
      _prefs.getBool(_lockScreenEnabledKey) ?? fallback;

  Future<void> saveLockScreenEnabled(bool enabled) =>
      _prefs.setBool(_lockScreenEnabledKey, enabled);

  // -- Appearance -------------------------------------------------------------

  String loadThemeMode(String fallback) =>
      _prefs.getString(_themeModeKey) ?? fallback;

  Future<void> saveThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  int loadPrimaryColorIndex(int fallback) =>
      _prefs.getInt(_primaryColorIndexKey) ?? fallback;

  Future<void> savePrimaryColorIndex(int index) =>
      _prefs.setInt(_primaryColorIndexKey, index);

  int? loadPrimaryColorArgb() => _prefs.getInt(_primaryColorArgbKey);

  Future<void> savePrimaryColorArgb(int color) async {
    if (!await _prefs.setInt(_primaryColorArgbKey, color)) {
      throw StateError('Primary color could not be saved');
    }
  }

  int? loadWidgetBackgroundColor() => _prefs.getInt(_widgetBackgroundColorKey);

  Future<void> saveWidgetBackgroundColor(int? color) async {
    final saved = color == null
        ? await _prefs.remove(_widgetBackgroundColorKey)
        : await _prefs.setInt(_widgetBackgroundColorKey, color);
    if (!saved) throw StateError('Widget background could not be saved');
  }

  // -- Locale -----------------------------------------------------------------

  String loadLocale(String fallback) =>
      _prefs.getString(_localeKey) ?? fallback;

  Future<void> saveLocale(String value) => _prefs.setString(_localeKey, value);

  // -- Player controls --------------------------------------------------------

  bool loadPreviousGoesToPrevious(bool fallback) =>
      _prefs.getBool(_previousGoesToPreviousKey) ?? fallback;

  Future<void> savePreviousGoesToPrevious(bool value) =>
      _prefs.setBool(_previousGoesToPreviousKey, value);

  // -- Player actions ---------------------------------------------------------

  bool loadHideQuickDelete(bool fallback) =>
      _prefs.getBool(_hideQuickDeleteKey) ?? fallback;

  Future<void> saveHideQuickDelete(bool value) =>
      _prefs.setBool(_hideQuickDeleteKey, value);

  double loadPlaybackSpeed(double fallback) =>
      (_prefs.getDouble(_playbackSpeedKey) ?? fallback).clamp(0.5, 3.0);

  Future<void> savePlaybackSpeed(double value) =>
      _prefs.setDouble(_playbackSpeedKey, value.clamp(0.5, 3.0).toDouble());

  bool loadEqualizerEnabled(bool fallback) =>
      _prefs.getBool(_equalizerEnabledKey) ?? fallback;

  Future<void> saveEqualizerEnabled(bool enabled) =>
      _prefs.setBool(_equalizerEnabledKey, enabled);

  List<double> loadEqualizerGains() =>
      (_prefs.getStringList(_equalizerGainsKey) ?? const [])
          .map(double.tryParse)
          .whereType<double>()
          .toList(growable: false);

  Future<void> saveEqualizerGains(List<double> gains) => _prefs.setStringList(
    _equalizerGainsKey,
    gains.map((gain) => gain.toString()).toList(growable: false),
  );

  int loadAudioFocusMode(int fallback) =>
      _prefs.getInt(_audioFocusModeKey) ?? fallback;

  Future<void> saveAudioFocusMode(int index) =>
      _prefs.setInt(_audioFocusModeKey, index);

  bool loadGaplessPlayback(bool fallback) =>
      _prefs.getBool(_gaplessPlaybackKey) ?? fallback;

  Future<void> saveGaplessPlayback(bool enabled) =>
      _prefs.setBool(_gaplessPlaybackKey, enabled);

  // -- Playback session -------------------------------------------------------

  SavedPlaybackSession? loadPlaybackSession() {
    final rawSnapshot = _prefs.getString(_sessionSnapshotKey);
    if (rawSnapshot != null) {
      try {
        final session = SavedPlaybackSession.fromJson(jsonDecode(rawSnapshot));
        if (session != null) return session;
      } on FormatException {
        // Fall back to the legacy keys if a snapshot was interrupted or corrupt.
      }
    }
    return _loadLegacyPlaybackSession();
  }

  SavedPlaybackSession? _loadLegacyPlaybackSession() {
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
    // A single native preference write prevents a process kill from leaving
    // queue, current item and track metadata from different playback moments.
    await _prefs.setString(_sessionSnapshotKey, jsonEncode(session.toJson()));
  }

  Future<void> clearPlaybackSession() async {
    await Future.wait(<Future<void>>[
      _prefs.remove(_sessionQueueKey),
      _prefs.remove(_sessionCurrentKey),
      _prefs.remove(_sessionPositionKey),
      _prefs.remove(_sessionRepeatKey),
      _prefs.remove(_sessionShuffleKey),
      _prefs.remove(_sessionTracksKey),
      _prefs.remove(_sessionSnapshotKey),
    ]);
  }
}
