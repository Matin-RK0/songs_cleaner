import '../entities/lyric_line.dart';

abstract final class LrcParser {
  static final _timestampPattern = RegExp(
    r'^\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]',
  );

  static List<LyricLine> parse(String source) {
    final lines = <LyricLine>[];
    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      var remaining = rawLine.trim();
      final timestamps = <Duration>[];
      while (true) {
        final match = _timestampPattern.firstMatch(remaining);
        if (match == null) break;
        final minutes = int.tryParse(match.group(1) ?? '');
        final seconds = int.tryParse(match.group(2) ?? '');
        final fraction = int.tryParse(match.group(3) ?? '0');
        if (minutes == null || seconds == null || fraction == null) break;
        final milliseconds = (match.group(3)?.length ?? 0) == 3
            ? fraction
            : fraction * 10;
        timestamps.add(
          Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
        );
        remaining = remaining.substring(match.end);
      }
      if (timestamps.isEmpty) continue;
      for (final timestamp in timestamps) {
        lines.add(LyricLine(timestamp: timestamp, text: remaining.trim()));
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(lines);
  }
}
