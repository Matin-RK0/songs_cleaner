import 'dart:convert';

import 'package:flutter/services.dart';

import '../../library/domain/entities/song.dart';
import '../domain/entities/playlist.dart';

class PlaylistTransferService {
  const PlaylistTransferService();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/file_transfer',
  );

  String encode(List<Playlist> playlists, List<Song> songs) {
    final songsById = {for (final song in songs) song.id: song};
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'songs_cleaner_playlists',
      'version': 1,
      'playlists': playlists
          .map(
            (playlist) => {
              'name': playlist.name,
              'songs': playlist.songIds
                  .map((id) => songsById[id])
                  .whereType<Song>()
                  .map((song) => {'path': song.path, 'title': song.title})
                  .toList(),
            },
          )
          .toList(),
    });
  }

  List<ImportedPlaylist> decode(String content) {
    final value = jsonDecode(content);
    if (value is! Map ||
        value['format'] != 'songs_cleaner_playlists' ||
        value['version'] != 1 ||
        value['playlists'] is! List) {
      throw const FormatException('Unsupported playlist file');
    }
    return (value['playlists'] as List)
        .whereType<Map>()
        .map((item) {
          final name = item['name'];
          final songs = item['songs'];
          if (name is! String || songs is! List) {
            throw const FormatException('Invalid playlist');
          }
          final paths = songs
              .whereType<Map>()
              .map((song) => song['path'])
              .whereType<String>()
              .toList(growable: false);
          return ImportedPlaylist(name: name, songPaths: paths);
        })
        .toList(growable: false);
  }

  Future<bool> exportToFile(List<Playlist> playlists, List<Song> songs) async {
    return await _channel.invokeMethod<bool>('saveJson', {
          'fileName': 'songs_cleaner_playlists.json',
          'content': encode(playlists, songs),
        }) ??
        false;
  }

  Future<List<ImportedPlaylist>?> importFromFile() async {
    final content = await _channel.invokeMethod<String>('openJson');
    return content == null ? null : decode(content);
  }

  Future<bool> sharePlaylists(
    List<Playlist> playlists,
    List<Song> songs,
  ) async {
    return await _channel.invokeMethod<bool>('shareJsonFile', {
          'title': 'Songs Cleaner playlists',
          'content': encode(playlists, songs),
        }) ??
        false;
  }
}

class ImportedPlaylist {
  const ImportedPlaylist({required this.name, required this.songPaths});

  final String name;
  final List<String> songPaths;
}
