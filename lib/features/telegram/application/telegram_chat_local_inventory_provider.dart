import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'telegram_controller.dart';

/// Playable inventory for an open chat, independent of search and browse filters.
/// Summaries use cache-only reads instead of this provider to avoid loading chats.
final telegramChatTotalLocalCountProvider = Provider.autoDispose
    .family<int, int>(
      (ref, id) => ref.watch(
        telegramChatProvider(id).select(
          (state) => state.tracks.where((track) => track.song != null).length,
        ),
      ),
    );
