import '../entities/play_history_entry.dart';

abstract final class PlayHistoryPolicy {
  static const int maxEntries = 200;

  static List<PlayHistoryEntry> record(
    List<PlayHistoryEntry> existing,
    PlayHistoryEntry entry,
  ) {
    return List.unmodifiable(
      <PlayHistoryEntry>[entry, ...existing].take(maxEntries),
    );
  }
}
