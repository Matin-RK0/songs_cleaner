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
}
