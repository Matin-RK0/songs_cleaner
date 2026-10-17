import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../models/resolved_history_entry.dart';
import 'play_history_controller.dart';

final resolvedHistoryProvider = Provider<List<ResolvedHistoryEntry>>((ref) {
  final songs = ref.watch(allSongsProvider);
  final entries = ref.watch(playHistoryProvider);
  final byId = {for (final song in songs) song.id: song};
  return List.unmodifiable(
    entries.map((entry) {
      final song = byId[entry.songId];
      return song == null
          ? null
          : ResolvedHistoryEntry(entry: entry, song: song);
    }).whereType<ResolvedHistoryEntry>(),
  );
});
