import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songs_cleaner/app/router/route_names.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../widgets/song_list_view.dart';

/// Song list of one artist or one album.
class GroupSongsScreen extends ConsumerWidget {
  const GroupSongsScreen({super.key, required this.args});

  final GroupSongsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = args.isArtist
        ? ref.watch(songsByArtistProvider(args.id))
        : ref.watch(songsByAlbumProvider(args.id));
    final currentId =
        ref.watch(playerProvider.select((state) => state.current?.id));

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: songs.isEmpty
          ? AppEmptyState(
              icon: Icons.music_off_rounded,
              title: context.l10n.emptyLibraryTitle,
            )
          : SongListView(
              songs: songs,
              currentSongId: currentId,
              onSongTap: (list, index) => ref
                  .read(playerProvider.notifier)
                  .playFromList(list, startIndex: index),
            ),
    );
  }
}
