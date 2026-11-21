import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../library/presentation/widgets/artwork_image.dart';

/// Playlist cover: a 2x2 collage of the first songs, a single cover when only
/// one exists, or a neutral placeholder when empty. Fills its parent when
/// [expand] is true (grid cards), otherwise a fixed [size] square.
class PlaylistArtwork extends StatelessWidget {
  const PlaylistArtwork({
    super.key,
    required this.songIds,
    this.size = 56,
    this.borderRadius,
    this.expand = false,
    this.heroTag,
    this.coverPath,
    this.placeholderIcon = Icons.queue_music_rounded,
  });

  final List<int> songIds;
  final double size;
  final BorderRadius? borderRadius;
  final bool expand;
  final String? heroTag;
  final String? coverPath;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? AppRadius.md;
    final covers = songIds.take(4).toList(growable: false);

    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 512);
    final automatic = covers.isEmpty
        ? _placeholder(colors)
        : _collage(colors, covers, cacheSize);
    final path = coverPath;
    final content = ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surfaceHigh),
        child: path == null
            ? automatic
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: cacheSize,
                errorBuilder: (_, _, _) => automatic,
              ),
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

  Widget _collage(AppColorTokens colors, List<int> covers, int pixels) {
    if (covers.length == 1) {
      return _cover(covers.first, size, pixels);
    }
    Widget cell(int index) => index < covers.length
        ? _cover(covers[index], size / 2, (pixels / 2).ceil())
        : ColoredBox(color: colors.surfaceHigh);
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(0)),
              Expanded(child: cell(1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(2)),
              Expanded(child: cell(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cover(int songId, double cellSize, int pixels) => ArtworkImage(
    songId: songId,
    size: cellSize,
    borderRadius: BorderRadius.zero,
    expand: true,
    resolution: pixels <= 128
        ? 128
        : pixels <= 256
        ? 256
        : 512,
  );

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
        child: Icon(placeholderIcon, size: size * 0.34, color: colors.textLow),
      ),
    );
  }
}
