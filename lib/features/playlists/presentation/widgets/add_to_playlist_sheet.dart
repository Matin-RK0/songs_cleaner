import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../library/domain/entities/song.dart';
import '../../application/providers/playlists_controller.dart';
import 'playlist_name_sheet.dart';

/// Bottom sheet for adding or removing a song across the user's playlists.
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) {
  return showAddSongsToPlaylistSheet(context, [song]);
}

Future<void> showAddSongsToPlaylistSheet(
  BuildContext context,
  List<Song> songs,
) {
  if (songs.isEmpty) return Future<void>.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    builder: (_) => _AddToPlaylistSheet(songs: songs),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final playlists = ref.watch(playlistsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.addToPlaylist,
              style: AppTypography.sheetTitle.copyWith(color: colors.textHigh),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.add_rounded, color: colors.primary),
          title: Text(
            l10n.newPlaylist,
            style: AppTypography.listTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          onTap: () async {
            final name = await showPlaylistNameSheet(
              context: context,
              title: l10n.newPlaylist,
              actionLabel: l10n.createAction,
            );
            if (name == null) return;
            final playlist = await ref
                .read(playlistsProvider.notifier)
                .create(name);
            await ref
                .read(playlistsProvider.notifier)
                .addSongs(playlist.id, songs.map((song) => song.id));
            if (!context.mounted) return;
            showAppSnackBar(context, l10n.addedToPlaylistToast(playlist.name));
            Navigator.of(context).pop();
          },
        ),
        Divider(height: 1, color: colors.outline),
        if (playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.playlistsEmptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textMedium),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final songIds = songs.map((song) => song.id).toSet();
                final contains = songIds.every(playlist.contains);
                return ListTile(
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.listTitle.copyWith(
                      color: colors.textHigh,
                    ),
                  ),
                  subtitle: Text(l10n.songCountLabel(playlist.songCount)),
                  trailing: Icon(
                    contains
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: contains ? colors.primary : colors.textLow,
                  ),
                  onTap: () {
                    final controller = ref.read(playlistsProvider.notifier);
                    if (contains) {
                      controller.removeSongs(playlist.id, songIds);
                    } else {
                      controller.addSongs(playlist.id, songIds);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
