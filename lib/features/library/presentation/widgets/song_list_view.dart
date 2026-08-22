import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../domain/entities/song.dart';
import '../widgets/song_tile.dart';

class SongListView extends ConsumerWidget {
  const SongListView({
    super.key,
    required this.songs,
    required this.currentSongId,
    this.onSongTap,
  });

  final List<Song> songs;
  final int? currentSongId;
  final void Function(List<Song> songs, int index)? onSongTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpacing.xl,
        start: AppSpacing.sm,
        end: AppSpacing.sm,
      ),
      physics: const ClampingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongTile(
          key: ValueKey(song.id),
          song: song,
          isCurrent: song.id == currentSongId,
          onTap: () => onSongTap?.call(songs, index),
          onDeleteDevice: (target) =>
              deleteSongFlow(context, ref, target),
        );
      },
    );
  }
}
