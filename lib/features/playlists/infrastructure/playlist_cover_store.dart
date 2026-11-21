import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final playlistCoverStoreProvider = Provider<PlaylistCoverStore>(
  (ref) => const PlaylistCoverStore(),
);

class PlaylistCoverStore {
  const PlaylistCoverStore();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/playlist_cover',
  );

  Future<String?> pick() => _channel.invokeMethod<String>('pick');

  Future<void> remove(String? path) async {
    if (path == null) return;
    try {
      final root = await getApplicationSupportDirectory();
      final file = File(path);
      if (file.parent.path !=
          '${root.path}${Platform.pathSeparator}playlist-covers') {
        return;
      }
      if (await file.exists()) await file.delete();
    } on Exception {
      // Retaining an unreferenced cover is safer than rolling back the playlist.
    }
  }
}
