import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/providers/library_providers.dart';

/// Album artwork for a song, decoded at the requested size through the
/// artwork cache. Falls back to a neutral music glyph.
class ArtworkImage extends ConsumerWidget {
  const ArtworkImage({
    super.key,
    required this.songId,
    this.size = 48,
    this.borderRadius,
  });

  final int songId;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(songArtworkProvider((songId, size.round())));
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.artworkPlaceholder,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadius.md,
            ),
          ),
          child: bytes.whenOrNull(
                data: (data) => data == null ? null : _image(data),
              ) ??
              _placeholder(),
        ),
      ),
    );
  }

  Widget _image(Uint8List data) {
    return ClipRRect(
      borderRadius: borderRadius ?? AppRadius.md,
      child: Image.memory(
        data,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.music_note_rounded,
      size: size * 0.5,
      color: AppColors.textLow,
    );
  }
}
