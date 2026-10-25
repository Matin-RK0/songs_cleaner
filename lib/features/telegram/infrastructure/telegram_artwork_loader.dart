import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/telegram_repository.dart';

typedef TelegramCoverKey = (int fileId, String path, String miniCover);

/// Only visible thumbnails are requested. Bound network concurrency and memory;
/// do not download whole audio files just to show their album art.
class TelegramArtworkLoader {
  TelegramArtworkLoader(this.repository);
  final TelegramRepository repository;
  final _cache = <TelegramCoverKey, Uint8List>{};
  final _pending = <TelegramCoverKey, Future<Uint8List?>>{};
  final _waiting = Queue<Completer<void>>();
  final _canceled = <TelegramCoverKey>{};
  int _active = 0;
  bool _closed = false;
  static const _capacity = 96;
  static const _parallel = 3;

  Future<Uint8List?> load(TelegramCoverKey key) async {
    if (_closed) return null;
    _canceled.remove(key);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final pending = _pending[key];
    if (pending != null) return pending;
    if (_pending.length >= _capacity) return _miniature(key);
    final future = _load(key);
    _pending[key] = future;
    try {
      return await future;
    } finally {
      _pending.remove(key);
      _canceled.remove(key);
    }
  }

  Future<Uint8List?> _load(TelegramCoverKey key) async {
    if (_active >= _parallel) {
      final waiter = Completer<void>();
      _waiting.add(waiter);
      await waiter.future;
    } else {
      _active++;
    }
    try {
      if (_closed || _canceled.contains(key)) return null;
      final path = await repository.coverPath(key.$1, localPath: key.$2);
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        if (bytes.isNotEmpty && !_closed) {
          _cache[key] = bytes;
          while (_cache.length > _capacity) {
            _cache.remove(_cache.keys.first);
          }
          return bytes;
        }
      }
    } catch (_) {
      /* Missing/offline thumbnails have a miniature fallback. */
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      } else {
        _active--;
      }
    }
    // Do not cache the fallback, so reconnecting can upgrade it to a full cover.
    return _closed ? null : _miniature(key);
  }

  Uint8List? _miniature(TelegramCoverKey key) {
    try {
      return key.$3.isEmpty ? null : base64Decode(key.$3);
    } on FormatException {
      return null;
    }
  }

  void release(TelegramCoverKey key) {
    if (_pending.containsKey(key)) _canceled.add(key);
  }

  void dispose() {
    _closed = true;
    _cache.clear();
  }
}
