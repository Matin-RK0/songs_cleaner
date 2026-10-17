import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../../library/domain/entities/song.dart';
import '../../application/providers/playlist_providers.dart';
import '../../application/providers/playlists_controller.dart';
import '../../application/playlist_transfer_service.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/smart_playlist.dart';
import '../widgets/playlist_artwork.dart';
import '../widgets/playlist_name_sheet.dart';
import '../widgets/playlist_song_sliver.dart';

enum _PlaylistAction { rename, delete }

const double _artworkSize = 168;

/// Detail view for a custom playlist or a smart playlist. Custom playlists
/// support reordering and removal; smart playlists are read-only.
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.args});

  final PlaylistDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customId = args.playlistId;
    final smartKind = args.smartKind;

    Playlist? playlist;
    List<Song> songs;
    String title;

    if (customId != null) {
      playlist = _playlistById(ref.watch(playlistsProvider), customId);
      songs = ref.watch(playlistSongsProvider(customId));
      title = playlist?.name ?? '';
    } else {
      songs = ref.watch(smartPlaylistSongsProvider(smartKind!));
      title = _smartTitle(l10n, smartKind);
    }

    // The playlist can vanish while open (e.g. deleted from this screen).
    if (customId != null && playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(
          icon: Icons.queue_music_rounded,
          title: l10n.playlistEmptySongsTitle,
          message: l10n.playlistEmptySongsMessage,
        ),
      );
    }

    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );
    final isCustom = playlist != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              tooltip: l10n.shuffleTooltip,
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () =>
                  ref.read(playerProvider.notifier).playAllShuffled(songs),
            ),
          if (isCustom)
            IconButton(
              tooltip: l10n.sharePlaylists,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _sharePlaylist(context, playlist!, songs),
            ),
          if (isCustom)
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => _showActions(context, ref, playlist!),
            ),
        ],
      ),
      body: songs.isEmpty
          ? _EmptyView(kind: smartKind, isCustom: isCustom)
          : CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PlaylistHeader(
                    songs: songs,
                    heroTag: customId == null ? null : 'playlist-art-$customId',
                    isCustom: isCustom,
                    onPlayAll: () => ref
                        .read(playerProvider.notifier)
                        .playFromList(songs, startIndex: 0),
                    onShuffle: () => ref
                        .read(playerProvider.notifier)
                        .playAllShuffled(songs),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                    end: AppSpacing.sm,
                  ),
                  sliver: PlaylistSongSliver(
                    songs: songs,
                    currentSongId: currentId,
                    onSongTap: (list, index) => ref
                        .read(playerProvider.notifier)
                        .playFromList(list, startIndex: index),
                    onReorder: isCustom
                        ? (oldIndex, newIndex) => ref
                              .read(playlistsProvider.notifier)
                              .reorder(playlist!.id, oldIndex, newIndex)
                        : null,
                    onRemove: isCustom
                        ? (song) => ref
                              .read(playlistsProvider.notifier)
                              .removeSong(playlist!.id, song.id)
                        : null,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl + 72),
                ),
              ],
            ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final l10n = context.l10n;
    final colors = context.colors;
    final action = await showModalBottomSheet<_PlaylistAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.renamePlaylist),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PlaylistAction.rename),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              iconColor: colors.danger,
              textColor: colors.danger,
              title: Text(l10n.deletePlaylist),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PlaylistAction.delete),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case _PlaylistAction.rename:
        final name = await showPlaylistNameSheet(
          context: context,
          title: l10n.renamePlaylist,
          actionLabel: l10n.saveAction,
          initialName: playlist.name,
        );
        if (name == null || !context.mounted) return;
        await ref.read(playlistsProvider.notifier).rename(playlist.id, name);
        if (!context.mounted) return;
        showAppSnackBar(context, l10n.playlistRenamedToast);
      case _PlaylistAction.delete:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: l10n.deletePlaylistConfirmTitle(playlist.name),
          message: l10n.deletePlaylistConfirmMessage,
          confirmLabel: l10n.delete,
          cancelLabel: l10n.cancel,
          destructive: true,
        );
        if (!confirmed || !context.mounted) return;
        await ref.read(playlistsProvider.notifier).remove(playlist.id);
        if (!context.mounted) return;
        showAppSnackBar(context, l10n.playlistDeletedToast(playlist.name));
        Navigator.of(context).maybePop();
    }
  }

  Future<void> _sharePlaylist(
    BuildContext context,
    Playlist playlist,
    List<Song> songs,
  ) async {
    try {
      final shared = await const PlaylistTransferService().sharePlaylists([
        playlist,
      ], songs);
      if (shared && context.mounted) {
        showAppSnackBar(context, context.l10n.playlistsShared);
      }
    } on Exception {
      if (context.mounted) {
        showAppSnackBar(
          context,
          context.l10n.playlistTransferFailed,
          error: true,
        );
      }
    }
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({
    required this.songs,
    required this.isCustom,
    required this.onPlayAll,
    required this.onShuffle,
    this.heroTag,
  });

  final List<Song> songs;
  final bool isCustom;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final total = songs.fold<Duration>(
      Duration.zero,
      (sum, song) => sum + song.duration,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          PlaylistArtwork(
            songIds: songs.take(4).map((song) => song.id).toList(),
            size: _artworkSize,
            borderRadius: AppRadius.xl,
            heroTag: heroTag,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.playlistMetaLabel(songs.length, total.mmss),
            textAlign: TextAlign.center,
            style: AppTypography.meta.copyWith(color: colors.textMedium),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onPlayAll,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.playTooltipShort),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(l10n.shuffleTooltip),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.kind, required this.isCustom});

  final SmartPlaylistKind? kind;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isCustom) {
      return AppEmptyState(
        icon: Icons.queue_music_rounded,
        title: l10n.playlistEmptySongsTitle,
        message: l10n.playlistEmptySongsMessage,
      );
    }
    return switch (kind!) {
      SmartPlaylistKind.liked => AppEmptyState(
        icon: Icons.favorite_border_rounded,
        title: l10n.likedEmptyTitle,
        message: l10n.likedEmptyMessage,
      ),
      SmartPlaylistKind.mostPlayed => AppEmptyState(
        icon: Icons.local_fire_department_rounded,
        title: l10n.mostPlayedEmptyTitle,
        message: l10n.mostPlayedEmptyMessage,
      ),
      SmartPlaylistKind.recentlyAdded => AppEmptyState(
        icon: Icons.library_music_rounded,
        title: l10n.emptyLibraryTitle,
        message: l10n.emptyLibraryMessage,
      ),
    };
  }
}

Playlist? _playlistById(List<Playlist> playlists, String id) {
  for (final playlist in playlists) {
    if (playlist.id == id) return playlist;
  }
  return null;
}

String _smartTitle(AppLocalizations l10n, SmartPlaylistKind kind) =>
    switch (kind) {
      SmartPlaylistKind.liked => l10n.smartLikedTitle,
      SmartPlaylistKind.recentlyAdded => l10n.smartRecentTitle,
      SmartPlaylistKind.mostPlayed => l10n.smartMostPlayedTitle,
    };
