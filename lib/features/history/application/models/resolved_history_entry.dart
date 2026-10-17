import '../../../library/domain/entities/song.dart';
import '../../domain/entities/play_history_entry.dart';

class ResolvedHistoryEntry {
  const ResolvedHistoryEntry({required this.entry, required this.song});

  final PlayHistoryEntry entry;
  final Song song;
}
