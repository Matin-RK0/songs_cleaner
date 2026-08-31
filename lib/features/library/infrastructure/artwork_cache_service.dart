import 'dart:collection';
import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';

/// In-memory LRU cache for decoded artwork bytes so list tiles and the
/// player screen do not hammer the MediaStore on every rebuild.
class ArtworkCacheService {
  ArtworkCacheService({this.maxEntries = 256});

  final int maxEntries;
  final OnAudioQuery _query = OnAudioQuery();

  final LinkedHashMap<(int, int), Uint8List?> _cache = LinkedHashMap();

  Future<Uint8List?> artworkFor(int songId, {required int size}) async {
    final key = (songId, size);
    if (_cache.containsKey(key)) {
      // Refresh position so the entry counts as most recently used.
      final cached = _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }
    Uint8List? bytes;
    try {
      bytes = await _query.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: size,
        format: ArtworkFormat.JPEG,
        // The artwork is also used as a large player/background image. Keep
        // the source JPEG at full quality and let Flutter scale it for the
        // actual widget size.
        quality: 100,
      );
    } catch (_) {
      bytes = null;
    }
    _cache[key] = bytes;
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return bytes;
  }
}
