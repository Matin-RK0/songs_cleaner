import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/song.dart';

/// Reads the device music library through the platform MediaStore.
class DeviceMusicDataSource {
  DeviceMusicDataSource(this._query);

  final OnAudioQuery _query;

  Future<List<Song>> fetchSongs() async {
    final models = await _query.querySongs();
    return models
        .map(_mapSong)
        .where((song) => song.hasFile)
        .toList(growable: false);
  }

  /// Returns songs added to the device on or after [dateAddedSeconds], newest
  /// first. The query is ordered by date added so the scan can stop as soon as
  /// it reaches already-known entries; only the freshly added rows are mapped
  /// and file-checked, keeping periodic syncs cheap.
  Future<List<Song>> fetchSongsNewerThan(int dateAddedSeconds) async {
    final models = await _query.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
    );
    final fresh = <Song>[];
    for (final model in models) {
      if ((model.dateAdded ?? 0) < dateAddedSeconds) break;
      final song = _mapSong(model);
      if (!song.hasFile) continue;
      if (await File(song.path).exists()) fresh.add(song);
    }
    return fresh;
  }

  /// Returns the newest usable MediaStore item. This is used by a cold-start
  /// media command before the library UI exists.
  Future<Song?> fetchNewestExistingSong() async {
    final newestFirst = await fetchSongs()
      ..sort((a, b) => b.dateAddedSeconds.compareTo(a.dateAddedSeconds));

    for (final song in newestFirst) {
      if (await File(song.path).exists()) {
        return song;
      }
    }
    return null;
  }

  Song _mapSong(SongModel model) {
    final title = model.title.trim();
    return Song(
      id: model.id,
      title: title.isEmpty ? _fileNameFallback(model.data) : title,
      artist: _cleanUnknown(model.artist),
      album: _cleanUnknown(model.album),
      albumId: model.albumId ?? -1,
      artistId: model.artistId ?? -1,
      duration: Duration(milliseconds: model.duration ?? 0),
      path: model.data.trim(),
      sizeBytes: model.size,
      dateAddedSeconds: model.dateAdded ?? 0,
      genre: _cleanUnknown(model.genre),
      // Some Samsung MediaStore rows expose genre_id as text. The current
      // on_audio_query model casts it to int and throws before returning the
      // song, while the app does not need the numeric genre id for display or
      // filtering.
      genreId: -1,
      composer: _cleanUnknown(model.composer),
      trackNumber: model.track ?? 0,
      dateModifiedSeconds: model.dateModified ?? 0,
      fileExtension: _fileExtension(model.data),
      folderPath: _folderPath(model.data),
    );
  }

  static String _cleanUnknown(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == '<unknown>') return '';
    return trimmed;
  }

  static String _fileNameFallback(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static String _folderPath(String path) {
    final separator = Platform.pathSeparator;
    final lastSeparator = path.lastIndexOf(separator);
    return lastSeparator > 0 ? path.substring(0, lastSeparator) : '';
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 && dot < path.length - 1
        ? path.substring(dot + 1).toLowerCase()
        : '';
  }
}
