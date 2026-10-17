import '../entities/play_history_entry.dart';

abstract interface class PlayHistoryRepository {
  List<PlayHistoryEntry> load();

  Future<void> save(List<PlayHistoryEntry> entries);

  Future<void> clear();
}
