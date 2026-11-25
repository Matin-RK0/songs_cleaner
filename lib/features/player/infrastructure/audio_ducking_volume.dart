/// Owns temporary player-volume changes, independent of Android's stream volume.
class AudioDuckingVolume {
  AudioDuckingVolume({required this._read, required this._write});

  final double Function() _read;
  final Future<void> Function(double) _write;
  Future<void> _pending = Future<void>.value();
  double? _original;
  double? _appliedGain;
  bool _requested = false;
  int _queued = 0;

  bool get isRequested => _requested;
  bool get needsRestore => _requested || _original != null;
  bool get hasPendingChange => _queued > 0;

  Future<void> duck(int percent) {
    _requested = true;
    final gain = percent.clamp(0, 100) / 100;
    return _enqueue(() async {
      if (_appliedGain == gain) return;
      final original = _original ??= _read();
      await _write(original * gain);
      _appliedGain = gain;
    });
  }

  Future<void> restore() {
    if (!needsRestore) return _pending;
    _requested = false;
    return _enqueue(() async {
      final original = _original;
      if (original == null) return;
      // Keep the baseline until the restore is acknowledged. A failed platform
      // write can then be retried on the next focus or playback action.
      _appliedGain = null;
      await _write(original);
      _original = null;
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _queued++;
    final result = _pending
        .then((_) => operation())
        .whenComplete(() => _queued--);
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
