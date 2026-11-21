import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/alphabet_index_rail.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/domain/entities/song.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../application/playlist_transfer_service.dart';
import '../../application/providers/playlist_providers.dart';
import '../../application/providers/playlists_controller.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/smart_playlist.dart';
import '../../domain/playlist_order.dart';
import '../widgets/playlist_detail_header.dart';
import '../widgets/playlist_name_sheet.dart';
import '../widgets/playlist_song_sliver.dart';
import '../widgets/playlist_sort_button.dart';
import '../widgets/smart_playlist_presentation.dart';

enum _PlaylistAction {
  edit,
  rename,
  cover,
  resetCover,
  share,
  equalizer,
  settings,
  delete,
}

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.args});

  final PlaylistDetailArgs args;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  final _selected = <int>{};
  var _editing = false;
  var _smartOrder = PlaylistTrackOrder.custom;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.args.playlistId;
    final kind = widget.args.smartKind;
    Playlist? playlist;
    if (id != null) {
      ref.watch(playlistsProvider);
      playlist = ref.read(playlistsProvider.notifier).playlistById(id);
      if (playlist == null) {
        return Scaffold(
          appBar: AppBar(),
          body: AppEmptyState(
            icon: Icons.queue_music_rounded,
            title: l10n.playlistEmptySongsTitle,
          ),
        );
      }
    }

    final order = playlist?.trackOrder ?? _smartOrder;
    final view = ref.watch(playlistTrackViewProvider((id, kind, order)));
    final songs = view.songs;
    final title = playlist?.name ?? kind!.title(l10n);
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );
    final controller = ref.read(playlistsProvider.notifier);
    final player = ref.read(playerProvider.notifier);
    final editable = playlist != null && _editing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.playlistsTab,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (playlist != null) ...[
            IconButton(
              tooltip: playlist.isFavorite
                  ? l10n.removeFromFavorites
                  : l10n.addToFavorites,
              isSelected: playlist.isFavorite,
              selectedIcon: Icon(
                Icons.favorite_rounded,
                color: context.colors.danger,
              ),
              icon: const Icon(Icons.favorite_border_rounded),
              onPressed: () => controller.toggleFavorite(id!),
            ),
            IconButton(
              tooltip: l10n.playlistAddTracks,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addTracks(playlist!),
            ),
          ],
          _PlaylistMenu(
            playlist: playlist,
            editing: editable,
            hasSongs: songs.isNotEmpty,
            onSelected: (action) => _onAction(action, playlist, songs),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (editable)
              PlaylistEditToolbar(
                count: _selected.length,
                onDone: _finishEditing,
                onSelectAll: songs.isEmpty
                    ? null
                    : () => setState(() {
                        if (_selected.length == songs.length) {
                          _selected.clear();
                        } else {
                          _selected.addAll(songs.map((song) => song.id));
                        }
                      }),
                onPlay: _selected.isEmpty
                    ? null
                    : () {
                        final selection = songs
                            .where((song) => _selected.contains(song.id))
                            .toList(growable: false);
                        if (selection.isNotEmpty) {
                          player.playFromList(selection, startIndex: 0);
                        }
                        _finishEditing();
                      },
                onRemove: _selected.isEmpty
                    ? null
                    : () => _removeTracks(playlist!, Set.of(_selected)),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            key: _headerKey,
                            children: [
                              PlaylistDetailHeader(
                                title: title,
                                duration: view.duration,
                                songCount: songs.length,
                                artworkIds: view.artworkIds,
                                playlist: playlist,
                                emptyIcon:
                                    kind?.icon ?? Icons.queue_music_rounded,
                              ),
                              if (songs.isNotEmpty)
                                PlaylistTrackControls(
                                  sort: PlaylistSortButton(
                                    current: order,
                                    options: PlaylistTrackOrder.values,
                                    labelOf: (value) => playlistTrackOrderLabel(
                                      l10n,
                                      value,
                                      custom: playlist != null,
                                    ),
                                    onSelected: (value) {
                                      jumpToListRow(_scroll, 0);
                                      if (id != null) {
                                        controller.setTrackOrder(id, value);
                                      } else {
                                        setState(() => _smartOrder = value);
                                      }
                                    },
                                  ),
                                  onPlay: () =>
                                      player.playFromList(songs, startIndex: 0),
                                  onShuffle: () =>
                                      player.playAllShuffled(songs),
                                ),
                            ],
                          ),
                        ),
                        if (songs.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyPlaylist(
                              kind: kind,
                              onAdd: playlist == null
                                  ? null
                                  : () => _addTracks(playlist!),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsetsDirectional.only(
                              start: AppSpacing.sm,
                              end: AppSpacing.sm,
                            ),
                            sliver: PlaylistSongSliver(
                              songs: songs,
                              currentSongId: currentId,
                              onSongTap: (list, index) =>
                                  player.playFromList(list, startIndex: index),
                              selectionMode: editable,
                              selectedSongIds: _selected,
                              onSelectionChanged: playlist == null
                                  ? null
                                  : _toggleSelection,
                              onReorder:
                                  editable &&
                                      order == PlaylistTrackOrder.custom &&
                                      _selected.isEmpty
                                  ? (from, to) => controller.reorderVisible(
                                      id!,
                                      songs,
                                      from,
                                      to,
                                    )
                                  : null,
                              onRemove: playlist == null
                                  ? null
                                  : (song) =>
                                        _removeTracks(playlist!, {song.id}),
                              showTrackMenu: true,
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.lg),
                        ),
                      ],
                    ),
                  ),
                  AlphabetIndexRail(
                    index: view.alphabet,
                    onJump: (row) {
                      final header =
                          _headerKey.currentContext?.size?.height ?? 0;
                      jumpToListRow(
                        _scroll,
                        header + row * PlaylistSongSliver.itemExtent,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: currentId == null ? null : const MiniPlayerBar(),
    );
  }

  void _toggleSelection(int id) => setState(() {
    _editing = true;
    if (!_selected.remove(id)) _selected.add(id);
  });

  void _finishEditing() => setState(() {
    _editing = false;
    _selected.clear();
  });

  Future<void> _addTracks(Playlist playlist) async {
    final added = await Navigator.of(
      context,
    ).pushNamed<bool>(RouteNames.playlistTrackPicker, arguments: playlist.id);
    if (mounted && added == true) {
      showAppSnackBar(
        context,
        context.l10n.addedToPlaylistToast(playlist.name),
      );
    }
  }

  Future<void> _removeTracks(Playlist playlist, Set<int> ids) async {
    await ref.read(playlistsProvider.notifier).removeSongs(playlist.id, ids);
    if (!mounted) return;
    setState(() => _selected.removeAll(ids));
    showAppSnackBar(
      context,
      context.l10n.removedFromPlaylistToast(ids.length, playlist.name),
    );
  }

  Future<void> _onAction(
    _PlaylistAction action,
    Playlist? playlist,
    List<Song> songs,
  ) async {
    final l10n = context.l10n;
    final controller = ref.read(playlistsProvider.notifier);
    switch (action) {
      case _PlaylistAction.edit:
        if (_editing) {
          _finishEditing();
        } else {
          setState(() => _editing = true);
        }
      case _PlaylistAction.rename:
        final name = await showPlaylistNameSheet(
          context: context,
          title: l10n.renamePlaylist,
          actionLabel: l10n.saveAction,
          initialName: playlist!.name,
        );
        if (name == null || !mounted) return;
        await controller.rename(playlist.id, name);
        if (mounted) showAppSnackBar(context, l10n.playlistRenamedToast);
      case _PlaylistAction.cover:
      case _PlaylistAction.resetCover:
        try {
          if (action == _PlaylistAction.cover) {
            await controller.pickCover(playlist!.id);
          } else {
            await controller.resetCover(playlist!.id);
          }
        } on Exception {
          if (mounted) {
            showAppSnackBar(context, l10n.playlistCoverFailed, error: true);
          }
        }
      case _PlaylistAction.share:
        try {
          final shared = await const PlaylistTransferService().sharePlaylists([
            playlist!,
          ], songs);
          if (shared && mounted) showAppSnackBar(context, l10n.playlistsShared);
        } on Exception {
          if (mounted) {
            showAppSnackBar(context, l10n.playlistTransferFailed, error: true);
          }
        }
      case _PlaylistAction.equalizer:
        Navigator.of(context).pushNamed(RouteNames.equalizer);
      case _PlaylistAction.settings:
        Navigator.of(context).pushNamed(RouteNames.settings);
      case _PlaylistAction.delete:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: l10n.deletePlaylistConfirmTitle(playlist!.name),
          message: l10n.deletePlaylistConfirmMessage,
          confirmLabel: l10n.delete,
          cancelLabel: l10n.cancel,
          destructive: true,
        );
        if (!confirmed || !mounted) return;
        await controller.remove(playlist.id);
        if (!mounted) return;
        showAppSnackBar(context, l10n.playlistDeletedToast(playlist.name));
        Navigator.of(context).maybePop();
    }
  }
}

class _PlaylistMenu extends StatelessWidget {
  const _PlaylistMenu({
    required this.playlist,
    required this.editing,
    required this.hasSongs,
    required this.onSelected,
  });

  final Playlist? playlist;
  final bool editing;
  final bool hasSongs;
  final ValueChanged<_PlaylistAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_PlaylistAction>(
      tooltip: l10n.moreActions,
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (playlist != null) ...[
          PopupMenuItem(
            value: _PlaylistAction.edit,
            enabled: hasSongs || editing,
            child: Text(
              editing ? l10n.playlistFinishEditing : l10n.playlistEditTracks,
            ),
          ),
          PopupMenuItem(
            value: _PlaylistAction.rename,
            child: Text(l10n.renamePlaylist),
          ),
          if (Platform.isAndroid)
            PopupMenuItem(
              value: _PlaylistAction.cover,
              child: Text(l10n.playlistChangeCover),
            ),
          if (playlist?.coverPath != null)
            PopupMenuItem(
              value: _PlaylistAction.resetCover,
              child: Text(l10n.playlistResetCover),
            ),
          PopupMenuItem(
            value: _PlaylistAction.share,
            child: Text(l10n.sharePlaylists),
          ),
        ],
        if (Platform.isAndroid)
          PopupMenuItem(
            value: _PlaylistAction.equalizer,
            child: Text(l10n.equalizerTitle),
          ),
        PopupMenuItem(
          value: _PlaylistAction.settings,
          child: Text(l10n.settingsTitle),
        ),
        if (playlist != null)
          PopupMenuItem(
            value: _PlaylistAction.delete,
            child: Text(
              l10n.deletePlaylist,
              style: TextStyle(color: context.colors.danger),
            ),
          ),
      ],
    );
  }
}

class _EmptyPlaylist extends StatelessWidget {
  const _EmptyPlaylist({required this.kind, this.onAdd});

  final SmartPlaylistKind? kind;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, message) = switch (kind) {
      SmartPlaylistKind.liked => (l10n.likedEmptyTitle, l10n.likedEmptyMessage),
      SmartPlaylistKind.mostPlayed => (
        l10n.mostPlayedEmptyTitle,
        l10n.mostPlayedEmptyMessage,
      ),
      SmartPlaylistKind.recentlyAdded => (
        l10n.emptyLibraryTitle,
        l10n.emptyLibraryMessage,
      ),
      SmartPlaylistKind.recentlyPlayed => (
        l10n.smartRecentlyPlayedTitle,
        l10n.smartRecentlyPlayedEmpty,
      ),
      null => (l10n.playlistEmptySongsTitle, null),
    };
    return Column(
      children: [
        AppEmptyState(
          icon: kind?.icon ?? Icons.queue_music_rounded,
          title: title,
          message: message,
        ),
        if (onAdd != null)
          PrimaryActionButton(
            label: l10n.playlistAddTracks,
            icon: Icons.add_rounded,
            onPressed: onAdd!,
          ),
      ],
    );
  }
}
