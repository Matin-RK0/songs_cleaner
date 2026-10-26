import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../domain/entities/song.dart';
import 'song_tile.dart';

/// Locate by identity in the displayed order, independently of the play queue.
void scrollToSong({
  required ScrollController controller,
  required List<Song> songs,
  required int songId,
  required bool reduceMotion,
}) {
  if (!controller.hasClients) return;
  final index = songs.indexWhere((song) => song.id == songId);
  if (index < 0) return;

  final position = controller.position;
  if (!position.hasContentDimensions) return;
  final target = (index * SongTile.itemExtent).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if (reduceMotion) {
    controller.jumpTo(target);
  } else {
    controller.animateTo(
      target,
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );
  }
}
