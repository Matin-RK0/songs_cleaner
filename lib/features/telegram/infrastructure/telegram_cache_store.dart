import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show compute;

/// Single-flight load and coalesced atomic snapshots. JSON work never runs on
/// Flutter's UI isolate, and callers can await durability before deleting audio.
class TelegramCacheStore {
  TelegramCacheStore(this.directory);
  final Future<Directory> Function() directory;
  Map<String, dynamic>? _data;
  Future<Map<String, dynamic>>? _loading;
  Future<void>? _saving;
  int _version = 0;

  Future<Map<String, dynamic>> load() =>
      _data != null ? Future.value(_data!) : _loading ??= _read();
  Future<Map<String, dynamic>> _read() async {
    try {
      final raw = await File(
        '${(await directory()).path}/library-v1.json',
      ).readAsString();
      _data = await compute(_decode, raw);
    } catch (_) {
      _data = {};
    }
    return _data!;
  }

  Future<void> save() {
    _version++;
    if (_saving != null) return _saving!;
    final saving = _flush();
    _saving = saving;
    saving.then(
      (_) {
        _saving = null;
      },
      onError: (Object _) {
        _saving = null;
      },
    );
    return saving;
  }

  Future<void> _flush() async {
    var saved = 0;
    while (saved < _version) {
      final version = _version;
      final snapshot = Map<String, dynamic>.from(_data!);
      final encoded = await compute(_encode, snapshot);
      final file = File('${(await directory()).path}/library-v1.json');
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(encoded, flush: true);
      await temp.rename(file.path);
      saved = version;
    }
  }

  Future<void> clear() async {
    await load();
    _data = {};
    await save();
  }

  Future<void> flush() async {
    await _saving;
  }
}

String _encode(Map<String, dynamic> value) => jsonEncode(value);
Map<String, dynamic> _decode(String value) =>
    jsonDecode(value) as Map<String, dynamic>;
