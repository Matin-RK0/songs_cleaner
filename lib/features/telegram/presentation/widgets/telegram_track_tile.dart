import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../library/presentation/widgets/song_tile.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../../core/widgets/music_track_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/utils/file_size_format.dart';
import '../../../../app/router/route_names.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../application/telegram_download_controller.dart';
import 'telegram_download_control.dart';
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
    final selected = ref.watch(
      telegramChatProvider(
        id,
      ).select((s) => s.selected.contains(track.audio.key)),
    );
    final selecting = ref.watch(
      telegramChatProvider(id).select((s) => s.selected.isNotEmpty),
    );
    final current = ref.watch(
      playerProvider.select(
        (s) => track.song != null && s.current?.path == track.song!.path,
      ),
    );
    final l10n = context.l10n;
    final available = track.song != null;
    final status = available ? track.song!.duration.mmss : l10n.telegramCloud;
    void onSelect() => ref
        .read(telegramChatProvider(id).notifier)
        .toggleSelection(track.audio.key);
    final art = SizedBox.square(
      dimension: AppSpacing.trackArtwork,
      child: TelegramArtwork(track: track, current: current),
    );
    final subtitle = TelegramDownloadSubtitle(
      audio: track.audio,
      hideCompleted: track.song == null,
      fallback: track.audio.artist.isEmpty
          ? '$status · ${track.audio.size.readableFileSize}'
          : '${track.audio.artist} · $status',
    );
    if (available) {
      final song = track.song!;
      final favorite = ref.watch(
        libraryStatsProvider.select((s) => s.isFavorite(song.id)),
      );
      return SongTile(
        song: song,
        onTap: selecting ? onSelect : () => _play(ref),
        isCurrent: current,
        artwork: art,
        subtitle: subtitle,
        selected: selected,
        trailing: selecting ? _selectionIndicator(context, selected) : null,
        onSelectionLongPress: onSelect,
        showMoreButton: !selecting,
        extraActions: [
          (
            icon: Icons.open_in_new_rounded,
            label: l10n.telegramOpenMessage,
            action: () => _openMessage(context, ref),
          ),
        ],
        isFavorite: favorite,
        onToggleFavorite: song.id < 0
            ? null
            : () => ref
                  .read(libraryStatsProvider.notifier)
                  .toggleFavorite(song.id),
        onAddToPlaylist: song.id < 0
            ? null
            : (target) => showAddToPlaylistSheet(context, target),
        onShowInfo: song.id < 0
            ? null
            : () => Navigator.of(
                context,
              ).pushNamed(RouteNames.songDetails, arguments: song.id),
        onDeleteDevice: (target) => deleteSongFlow(context, ref, target),
      );
    }
    return MusicTrackCard(
      title: track.audio.title.isEmpty
          ? track.audio.fileName
          : track.audio.title,
      artwork: art,
      subtitle: subtitle,
      selected: selected,
      onTap: selecting ? onSelect : () => _showRemoteActions(context, ref),
      onLongPress: onSelect,
      progress: TelegramDownloadLine(id: track.audio.fileId),
      trailing: selecting
          ? _selectionIndicator(context, selected)
          : TelegramDownloadControl(
              audio: track.audio,
              enabled: connected,
              allowRedownload: true,
            ),
    );
  }

  Widget _selectionIndicator(BuildContext context, bool selected) =>
      SizedBox.square(
        dimension: kMinInteractiveDimension,
        child: Center(
          child: Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  void _play(WidgetRef ref) {
    if (ref.read(playerProvider).current?.path == track.song?.path) {
      ref.read(playerProvider.notifier).playPause();
      return;
    }
    final songs = ref.read(telegramChatSongsProvider(track.audio.chatId));
    final index = songs.indexWhere((song) => song.id == track.song?.id);
    if (index >= 0) {
      ref.read(playerProvider.notifier).playFromList(songs, startIndex: index);
    }
  }

  Future<void> _showRemoteActions(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: AppSpacing.allMd,
                child: Text(
                  track.audio.title.isEmpty
                      ? track.audio.fileName
                      : track.audio.title,
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(context.l10n.telegramOpenMessage),
                onTap: () {
                  Navigator.pop(sheet);
                  _openMessage(context, ref);
                },
              ),
              for (final play in [false, true])
                ListTile(
                  leading: Icon(
                    play
                        ? Icons.play_circle_outline_rounded
                        : Icons.download_rounded,
                  ),
                  title: Text(
                    play
                        ? context.l10n.telegramDownloadAndPlay
                        : context.l10n.telegramDownload,
                  ),
                  enabled: connected,
                  onTap: () {
                    Navigator.pop(sheet);
                    if (!ref
                        .read(telegramDownloadsProvider.notifier)
                        .enqueue(track.audio, play: play)) {
                      showAppSnackBar(
                        context,
                        context.l10n.telegramQueueFull,
                        error: true,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      );

  Future<void> _openMessage(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(telegramRepositoryProvider)
        .openMessage(track.audio);
    if (!opened && context.mounted) {
      showAppSnackBar(context, context.l10n.telegramErrorGeneric, error: true);
    }
  }
}
