import '../../library/domain/entities/song.dart';
import 'telegram_models.dart';

/// Reuses an existing local copy by filename and exact byte size.
/// Matching makes a file playable; it does not establish its original chat.
class TelegramLocalMatcher {
  TelegramLocalMatcher(List<Song> songs) {
    for (final song in songs) {
      final key = (basename(song.path), song.sizeBytes);
      (_byFile[key] ??= []).add(song);
      _byPath[song.path] = song;
    }
    // Stable choice across library refreshes when identical copies exist.
    for (final copies in _byFile.values) {
      copies.sort((a, b) => a.path.compareTo(b.path));
    }
  }
  final Map<(String, int), List<Song>> _byFile = {};
  final Map<String, Song> _byPath = {};
  static final _separator = RegExp(r'[/\\]');
  static String basename(String path) =>
      path.split(_separator).last.toLowerCase();
  static bool isTelegramPath(String path) => path
      .toLowerCase()
      .split(_separator)
      .any(
        (part) =>
            part == 'telegram' ||
            part.startsWith('telegram ') ||
            part == 'org.telegram.messenger' ||
            part == 'org.telegram.messenger.web',
      );

  List<Song> candidatesFor(TelegramAudio audio) => audio.size <= 0
      ? const []
      : List.unmodifiable(
          _byFile[(basename(audio.fileName), audio.size)] ?? const <Song>[],
        );

  TelegramTrack resolve(
    TelegramAudio audio,
    Map<String, String> bindings,
    Set<String> existingPaths,
  ) {
    final confirmed = bindings[audio.key];
    final path = confirmed != null && existingPaths.contains(confirmed)
        ? confirmed
        : existingPaths.contains(audio.localPath) && audio.localPath.isNotEmpty
        ? audio.localPath
        : null;
    if (path != null) {
      return TelegramTrack(
        audio,
        song:
            _byPath[path] ??
            Song(
              // TDLib file ids persist with its database and are disjoint from MediaStore.
              id: -audio.fileId,
              title: audio.title.isEmpty ? audio.fileName : audio.title,
              artist: audio.artist,
              album: '',
              albumId: -1,
              artistId: -1,
              duration: Duration(seconds: audio.duration),
              path: path,
              sizeBytes: audio.size,
              dateAddedSeconds: audio.date,
            ),
      );
    }
    for (final song in candidatesFor(audio)) {
      if (existingPaths.contains(song.path)) {
        return TelegramTrack(audio, song: song);
      }
    }
    return TelegramTrack(audio);
  }
}
