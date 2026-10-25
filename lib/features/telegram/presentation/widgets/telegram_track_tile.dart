import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../library/domain/entities/song.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import 'telegram_artwork.dart';

class TelegramTrackTile extends ConsumerWidget {
  const TelegramTrackTile({
    super.key,
    required this.track,
    required this.connected,
  });
  final TelegramTrack track;
  final bool connected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = track.audio.chatId;
    final downloading = ref.watch(
      telegramChatProvider(
        id,
      ).select((s) => s.downloading.contains(track.audio.key)),
    );
    final current = ref.watch(
      playerProvider.select(
        (s) => track.song != null && s.current?.id == track.song!.id,
      ),
    );
    final l10n = context.l10n;
    final available = track.song != null;
    final status = available
        ? track.song!.duration.mmss
        : track.candidates.isNotEmpty
        ? l10n.telegramSuggested
        : l10n.telegramCloud;
    return ListTile(
      contentPadding: AppSpacing.hMdVSm,
      leading: TelegramArtwork(track: track, current: current),
      title: Text(
        track.audio.title.isEmpty ? track.audio.fileName : track.audio.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.audio.artist.isEmpty ? status : '${track.audio.artist} · $status',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: available
          ? () => _play(ref)
          : track.candidates.isNotEmpty
          ? () => _link(context, ref)
          : null,
      trailing: downloading
          ? Tooltip(
              message: l10n.telegramDownloading,
              child: const SizedBox.square(
                dimension: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : available
          ? IconButton(
              tooltip: l10n.telegramPlayLocal,
              onPressed: () => _play(ref),
              icon: const Icon(Icons.play_arrow_rounded),
            )
          : track.candidates.isNotEmpty
          ? IconButton(
              tooltip: l10n.telegramLink,
              onPressed: () => _link(context, ref),
              icon: const Icon(Icons.link_rounded),
            )
          : IconButton(
              tooltip: l10n.telegramDownload,
              onPressed: connected
                  ? () => ref
                        .read(telegramChatProvider(id).notifier)
                        .download(track.audio)
                  : null,
              icon: const Icon(Icons.download_rounded),
            ),
    );
  }

  void _play(WidgetRef ref) {
    final songs = ref.read(telegramChatSongsProvider(track.audio.chatId));
    final index = songs.indexWhere((song) => song.id == track.song?.id);
    if (index >= 0) {
      ref.read(playerProvider.notifier).playFromList(songs, startIndex: index);
    }
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.telegramLinkTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(context.l10n.telegramLinkHint),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: track.candidates.length,
                itemBuilder: (context, index) {
                  final song = track.candidates[index];
                  return ListTile(
                    leading: const Icon(Icons.audio_file_outlined),
                    title: Text(song.title),
                    subtitle: Text(
                      song.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, song),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await ref
          .read(telegramChatProvider(track.audio.chatId).notifier)
          .bind(track.audio, selected);
    }
  }
}
