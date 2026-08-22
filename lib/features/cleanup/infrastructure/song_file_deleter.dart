import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../library/domain/entities/song.dart';

/// Deletes the underlying audio file from device storage.
/// Requires MANAGE_EXTERNAL_STORAGE ("All files access") on modern Android.
class SongFileDeleter {
  const SongFileDeleter();

  Future<void> delete(Song song) async {
    try {
      final file = File(song.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      throw SongDeleteFailure(song.path, error.toString());
    }
  }
}

final songFileDeleterProvider = Provider<SongFileDeleter>(
  (ref) => const SongFileDeleter(),
);
