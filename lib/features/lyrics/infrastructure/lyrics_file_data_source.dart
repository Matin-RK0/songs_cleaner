import 'dart:io';

import '../domain/entities/lyric_line.dart';
import '../domain/services/lrc_parser.dart';

class LyricsFileDataSource {
  Future<List<LyricLine>> loadForPath(String audioPath) async {
    final dot = audioPath.lastIndexOf('.');
    final base = dot > 0 ? audioPath.substring(0, dot) : audioPath;
    final candidates = <String>['$base.lrc', '$base.LRC'];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (!await file.exists()) continue;
      try {
        return LrcParser.parse(await file.readAsString());
      } on FileSystemException {
        return const [];
      }
    }
    return const [];
  }
}
