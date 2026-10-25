import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../application/telegram_artwork_provider.dart';
import '../../domain/telegram_models.dart';

class TelegramArtwork extends ConsumerWidget {
  const TelegramArtwork({super.key, required this.track, this.current = false});
  final TelegramTrack track;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = track.audio;
    final cover = ref.watch(
      telegramArtworkProvider((
        audio.coverFileId,
        audio.coverPath,
        audio.miniCover,
      )),
    );
    final localSong = track.song;
    final resolution =
        (AppSpacing.avatarSize * MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(1, 256);
    final localBytes = localSong != null && localSong.id >= 0
        ? ref.watch(songArtworkProvider((localSong.id, resolution))).value
        : null;
    final bytes = cover.value ?? localBytes;
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: AppSpacing.avatarSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: AppRadius.md,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                _image(bytes, resolution)
              else
                Icon(
                  track.hasLocalFile
                      ? Icons.music_note_rounded
                      : Icons.cloud_outlined,
                  color: colors.onSurfaceVariant,
                ),
              if (current)
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Icon(
                      Icons.equalizer_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(Uint8List bytes, int resolution) => ClipRRect(
    borderRadius: AppRadius.md,
    child: Image.memory(
      bytes,
      fit: BoxFit.cover,
      cacheWidth: resolution,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => Icon(
        Icons.music_note_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
