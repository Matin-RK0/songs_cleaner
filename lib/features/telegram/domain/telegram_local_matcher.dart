import '../../library/domain/entities/song.dart';
import 'telegram_models.dart';

/// Filename/size matches are suggestions, never proof of provenance.
class TelegramLocalMatcher {
  TelegramLocalMatcher(List<Song> songs) {
    for (final song in songs) {
      final name = basename(song.path);
      (_byName[name] ??= []).add(song);
      _byPath[song.path] = song;
    }
  }
  final Map<String, List<Song>> _byName = {};
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

  List<Song> candidatesFor(TelegramAudio audio) =>
      (_byName[basename(audio.fileName)] ?? const <Song>[])
          .where((song) => audio.size > 0 && song.sizeBytes == audio.size)
          .toList(growable: false);

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
    final candidates = candidatesFor(audio)
        .where((song) => existingPaths.contains(song.path))
        .toList(growable: false);
    return TelegramTrack(audio, candidates: candidates);
  }
}
