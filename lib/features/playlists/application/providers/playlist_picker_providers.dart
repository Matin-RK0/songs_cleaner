import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/alphabet_index.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../domain/services/playlist_picker_catalog.dart';
import 'playlists_controller.dart';

final _catalogProvider = Provider.autoDispose
    .family<List<PlaylistPickerEntry>, (String, PlaylistPickerTab)>((
      ref,
      input,
    ) {
      final (id, tab) = input;
      final existing = ref.watch(
        playlistsProvider.select((playlists) {
          for (final playlist in playlists) {
            if (playlist.id == id) return playlist.songIds;
          }
          return const <int>[];
        }),
      );
      return buildPlaylistPickerCatalog(
        ref.watch(allSongsProvider),
        existing,
        tab,
      );
    });

typedef PlaylistPickerView = ({
  List<PlaylistPickerEntry> rows,
  Map<String, int> alphabet,
  Set<int> ids,
});

final playlistPickerViewProvider = Provider.autoDispose
    .family<PlaylistPickerView, (String, PlaylistPickerTab, String)>((
      ref,
      input,
    ) {
      final (id, tab, query) = input;
      final rows = filterPlaylistPickerCatalog(
        ref.watch(_catalogProvider((id, tab))),
        tab,
        query,
      );
      return (
        rows: rows,
        alphabet: buildAlphabetIndex(rows.map((entry) => entry.title)),
        ids: {for (final entry in rows) ...entry.ids},
      );
    });
