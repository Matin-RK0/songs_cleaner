import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/providers/library_providers.dart';
import '../../domain/entities/song_collection.dart';
import '../widgets/song_list_view.dart';

class CollectionSongsScreen extends ConsumerWidget {
  const CollectionSongsScreen({super.key, required this.args});

  final CollectionSongsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = args.kind == SongCollectionKind.genre
        ? ref.watch(songsByGenreProvider(args.key))
        : ref.watch(songsByFolderProvider(args.key));
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );
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
