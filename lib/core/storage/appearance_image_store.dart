import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final appearanceImageStoreProvider = Provider(
  (ref) => const AppearanceImageStore(),
);

class AppearanceImageStore {
  const AppearanceImageStore();

  static const _channel = MethodChannel(
    'com.example.songs_cleaner/appearance_image',
  );

  Future<String?> pick() => _channel.invokeMethod<String>('pick');

  Future<void> remove(String? path) async {
    if (path == null) return;
    try {
      final root = await getApplicationSupportDirectory();
      final file = File(path);
      if (file.parent.path ==
          '${root.path}${Platform.pathSeparator}appearance-images') {
        await file.delete();
      }
    } on Exception {
      // File cleanup is best-effort; it must not undo a saved preference.
    }
  }
}
