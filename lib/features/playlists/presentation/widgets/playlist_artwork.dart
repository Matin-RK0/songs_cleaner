import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../library/presentation/widgets/artwork_image.dart';

/// Playlist cover: a 2x2 collage of the first songs, a single cover when only
/// one exists, or a neutral placeholder when empty. Fills its parent when
/// [expand] is true (grid cards), otherwise a fixed [size] square.
class PlaylistArtwork extends ConsumerWidget {
  const PlaylistArtwork({
    super.key,
    required this.songIds,
    this.size = 56,
    this.borderRadius,
    this.expand = false,
    this.heroTag,
  });

  final List<int> songIds;
  final double size;
  final BorderRadius? borderRadius;
  final bool expand;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final radius = borderRadius ?? AppRadius.md;
    final covers = songIds.take(4).toList(growable: false);

    final content = ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surfaceHigh),
        child: covers.isEmpty ? _placeholder(colors) : _collage(colors, covers),
      ),
    );

    final sized = expand
        ? content
        : SizedBox.square(dimension: size, child: content);
    if (heroTag == null) return RepaintBoundary(child: sized);
    return RepaintBoundary(
      child: Hero(tag: heroTag!, child: sized),
    );
  }

  Widget _collage(AppColorTokens colors, List<int> covers) {
    if (covers.length == 1) {
      return _cover(covers.first);
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _cover(covers[0])),
              Expanded(
                child: covers.length > 1
                    ? _cover(covers[1])
                    : _emptyCell(colors),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: covers.length > 2
                    ? _cover(covers[2])
                    : _emptyCell(colors),
              ),
              Expanded(
                child: covers.length > 3
                    ? _cover(covers[3])
                    : _emptyCell(colors),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cover(int songId) => ArtworkImage(
    songId: songId,
    size: size,
    borderRadius: BorderRadius.zero,
    expand: true,
    resolution: 260,
  );

  Widget _emptyCell(AppColorTokens colors) =>
      ColoredBox(color: colors.surfaceHigh);

  Widget _placeholder(AppColorTokens colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.surfaceHigh, colors.surfaceElevated],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: size * 0.34,
          color: colors.textLow,
        ),
      ),
    );
  }
}
