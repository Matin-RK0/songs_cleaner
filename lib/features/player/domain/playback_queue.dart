import 'dart:math';

import '../../library/domain/entities/song.dart';

/// Pure play-order logic: owns the effective play order, shuffle state and
/// the current index. No platform or Flutter dependencies, fully testable.
class PlaybackQueue {
  List<Song> _original = const [];
  List<Song> _order = const [];
  int _index = -1;
  bool _shuffled = false;

  static final Random _random = Random();

  /// Effective play order (shuffled when shuffle is enabled).
  List<Song> get songs => List.unmodifiable(_order);

  /// Canonical order as it was loaded (ignores shuffling).
  List<Song> get originalSongs => List.unmodifiable(_original);

  int get currentIndex => _index;

  int get length => _order.length;

  bool get isNotEmpty => _order.isNotEmpty;

  bool get shuffled => _shuffled;

  Song? get current =>
      (_index >= 0 && _index < _order.length) ? _order[_index] : null;

  Song? songAt(int index) =>
      (index >= 0 && index < _order.length) ? _order[index] : null;

  void load(List<Song> songs, {int startIndex = 0}) {
    _original = List.unmodifiable(songs);
    _shuffled = false;
    _order = _original;
    _index = songs.isEmpty ? -1 : startIndex.clamp(0, songs.length - 1);
  }

  void setShuffled(bool enabled) {
    if (enabled == _shuffled || _order.isEmpty) return;
    final currentSong = current;
    _shuffled = enabled;
    if (!enabled) {
      _order = _original;
      _index = currentSong == null ? -1 : _indexOfId(_order, currentSong.id);
      return;
    }
    // Keep the playing song first, shuffle everything after it.
    if (currentSong == null) {
      _order = _shuffleAll(_original);
      return;
    }
    final rest = _original.where((s) => s.id != currentSong.id).toList();
    final shuffledRest = _shuffleAll(rest);
    _order = [currentSong, ...shuffledRest];
    _index = 0;
  }

  /// Moves to the next track. Returns false when the queue ended without
  /// wrapping. When [wrap] is true it loops back to the first track.
  bool next({bool wrap = false}) {
    if (_order.isEmpty) return false;
    if (_index < _order.length - 1) {
      _index++;
      return true;
    }
    if (!wrap) return false;
    _index = 0;
    return true;
  }

  /// Moves to the previous track. At the start of a non-wrapping queue it
  /// returns false.
  bool previous({bool wrap = false}) {
    if (_order.isEmpty) return false;
    if (_index > 0) {
      _index--;
      return true;
    }
    if (!wrap) return false;
    _index = _order.length - 1;
    return true;
  }

  bool jumpTo(int index) {
    if (index < 0 || index >= _order.length) return false;
    _index = index;
    return true;
  }

  bool jumpToSong(int songId) => jumpTo(_indexOfId(_order, songId));

  /// Removes the currently playing track. The index stays put so playback
  /// continues with whatever followed the removed song.
  Song? removeCurrent() => removeById(current?.id ?? -1);

  Song? removeById(int? songId) {
    if (songId == null || songId < 0) return null;
    final orderIndex = _indexOfId(_order, songId);
    if (orderIndex == -1) return null;
    if (orderIndex < _index) _index--;
    // Current/after cases keep the index; _removeAt clamps at queue end.
    return _removeAt(orderIndex);
  }

  void clear() {
    _original = const [];
    _order = const [];
    _index = -1;
    _shuffled = false;
  }

  Song? _removeAt(int orderIndex) {
    final removed = _order[orderIndex];
    _order = List.unmodifiable(
      [..._order.sublist(0, orderIndex), ..._order.sublist(orderIndex + 1)],
    );
    _original = List.unmodifiable(
      _original.where((s) => s.id != removed.id),
    );
    if (_order.isEmpty) {
      _index = -1;
    } else if (_index >= _order.length) {
      _index = _order.length - 1;
    }
    return removed;
  }

  static int _indexOfId(List<Song> songs, int id) =>
      songs.indexWhere((s) => s.id == id);

  static List<Song> _shuffleAll(List<Song> input) {
    final list = [...input];
    for (var i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
