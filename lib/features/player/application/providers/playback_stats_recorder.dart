import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_stats_controller.dart';
import '../../../history/application/providers/play_history_controller.dart';
import 'player_controller.dart';

/// Records a play whenever a track starts or changes while playing, feeding the
/// "most played" smart playlist. Kept alive by [SongsCleanerApp]; the guard
/// avoids counting the frequent position-only state updates or a resume of the
/// same track. Lives in the player feature because it depends on [playerProvider].
final playbackStatsRecorderProvider = Provider<void>((ref) {
  ref.listen(playerProvider, (previous, next) {
    if (!next.playing) return;
    final songId = next.current?.id;
    if (songId == null) return;
    final sameTrackStillPlaying =
        (previous?.playing ?? false) && previous?.current?.id == songId;
    if (sameTrackStillPlaying) return;
    ref.read(libraryStatsProvider.notifier).recordPlay(songId);
    ref.read(playHistoryProvider.notifier).record(songId);
  });
});
