import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../app/router/route_names.dart';
import '../../../cleanup/application/cleanup_service.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../application/providers/library_controller.dart';
import '../../application/providers/library_stats_controller.dart';
import '../../domain/value_objects/song_sort.dart';
import '../../domain/value_objects/song_filter.dart';
import '../../domain/entities/song.dart';
import '../widgets/permission_gate_view.dart';
import '../widgets/song_list_view.dart';

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  final Set<int> _selectedIds = <int>{};

  void _toggleSelection(int songId) {
    setState(() {
      if (!_selectedIds.remove(songId)) _selectedIds.add(songId);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );

    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(context, ref, error),
      data: (state) {
        if (state.songs.isEmpty) {
          return AppEmptyState(
            icon: Icons.library_music_rounded,
            title: context.l10n.emptyLibraryTitle,
            message: context.l10n.emptyLibraryMessage,
          );
        }
        return Column(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _selectedIds.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('no-selection'))
                  : _SelectionToolbar(
                      key: const ValueKey('selection'),
                      count: _selectedIds.length,
                      onClose: _clearSelection,
                      onSelectAll: () => setState(() {
                        _selectedIds
                          ..clear()
                          ..addAll(state.visibleSongs.map((song) => song.id));
                      }),
                      onPlay: () {
                        final selected = state.visibleSongs
                            .where((song) => _selectedIds.contains(song.id))
                            .toList(growable: false);
                        if (selected.isEmpty) return;
                        ref
                            .read(playerProvider.notifier)
                            .playFromList(selected, startIndex: 0);
                        _clearSelection();
                      },
                      onQueue: () async {
                        final selected = state.visibleSongs.where(
                          (song) => _selectedIds.contains(song.id),
                        );
                        for (final song in selected) {
                          await ref
                              .read(playerProvider.notifier)
                              .addToQueue(song);
                        }
                        if (mounted) _clearSelection();
                      },
                      onFavorite: () async {
                        await ref
                            .read(libraryStatsProvider.notifier)
                            .addFavorites(_selectedIds);
                        if (mounted) _clearSelection();
                      },
                      onPlaylist: () async {
                        final selected = state.visibleSongs
                            .where((song) => _selectedIds.contains(song.id))
                            .toList(growable: false);
                        await showAddSongsToPlaylistSheet(context, selected);
                        if (mounted) _clearSelection();
                      },
                      onDelete: () => _deleteSelected(
                        state.visibleSongs
                            .where((song) => _selectedIds.contains(song.id))
                            .toList(growable: false),
                      ),
                      onInfo: _selectedIds.length == 1
                          ? () => Navigator.of(context).pushNamed(
                              RouteNames.songDetails,
                              arguments: _selectedIds.single,
                            )
                          : null,
                    ),
            ),
            Expanded(
              child: state.visibleSongs.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.noResultsTitle,
                      message: context.l10n.noResultsMessage,
                    )
                  : SongListView(
                      songs: state.visibleSongs,
                      currentSongId: currentId,
                      controller: widget.scrollController,
                      itemExtent: 72,
                      selectedSongIds: _selectedIds,
                      onSelectionChanged: _toggleSelection,
                      onSongTap: (songs, index) => ref
                          .read(playerProvider.notifier)
                          .playFromList(songs, startIndex: index),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final l10n = context.l10n;
    if (error is PermissionFailure) {
      return PermissionGateView(
        onRetry: () async {
          await ref.read(libraryProvider.notifier).refresh();
        },
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppErrorState(
            title: l10n.errorLoadFailedTitle,
            message: l10n.errorLoadFailedMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryActionButton(
            label: l10n.retry,
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(libraryProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected(List<Song> songs) async {
    if (songs.isEmpty) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.deleteSelectedTitle(songs.length),
      message: context.l10n.deleteSelectedMessage,
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
    );
    if (!confirmed || !mounted) return;

    var deleted = 0;
    var permissionMissing = false;
    for (final song in songs) {
      final result = await ref
          .read(cleanupServiceProvider)
          .deleteFromDevice(song);
      if (result is CleanupSuccess) deleted++;
      if (result is CleanupPermissionMissing) {
        permissionMissing = true;
        break;
      }
    }
    if (!mounted) return;
    _clearSelection();
    if (permissionMissing) {
      final openSettings = await showAppConfirmDialog(
        context: context,
        title: context.l10n.permissionTitle,
        message: context.l10n.permissionFilesMessage,
        confirmLabel: context.l10n.openSettings,
        cancelLabel: context.l10n.cancel,
      );
      if (openSettings && mounted) {
        await ref.read(mediaPermissionsProvider).openPermissionSettings();
      }
      return;
    }
    showAppSnackBar(context, context.l10n.deletedSongsCount(deleted));
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onSelectAll,
    required this.onPlay,
    required this.onQueue,
    required this.onFavorite,
    required this.onPlaylist,
    required this.onDelete,
    required this.onInfo,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onPlay;
  final VoidCallback onQueue;
  final VoidCallback onFavorite;
  final VoidCallback onPlaylist;
  final VoidCallback onDelete;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: 64,
        decoration: ShapeDecoration(
          color: colors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    l10n.selectedCount(count),
                    key: ValueKey(count),
                    style: AppTypography.emphasisTitle.copyWith(
                      color: colors.textHigh,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.selectAll,
                onPressed: onSelectAll,
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                tooltip: l10n.playTooltip,
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              PopupMenuButton<_SelectionAction>(
                tooltip: l10n.moreActions,
                onSelected: (action) {
                  switch (action) {
                    case _SelectionAction.queue:
                      onQueue();
                    case _SelectionAction.favorite:
                      onFavorite();
                    case _SelectionAction.playlist:
                      onPlaylist();
                    case _SelectionAction.info:
                      onInfo?.call();
                    case _SelectionAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _SelectionAction.queue,
                    child: Text(l10n.addToQueue),
                  ),
                  PopupMenuItem(
                    value: _SelectionAction.favorite,
                    child: Text(l10n.addToFavorites),
                  ),
                  PopupMenuItem(
                    value: _SelectionAction.playlist,
                    child: Text(l10n.addToPlaylist),
                  ),
                  if (onInfo != null)
                    PopupMenuItem(
                      value: _SelectionAction.info,
                      child: Text(l10n.songDetailsTitle),
                    ),
                  PopupMenuItem(
                    value: _SelectionAction.delete,
                    child: Text(
                      l10n.deleteAction,
                      style: AppTypography.body.copyWith(color: colors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SelectionAction { queue, favorite, playlist, info, delete }

/// Bottom sheet for choosing the song list ordering.
Future<void> showSortSheet(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final colors = context.colors;
  final current = ref.read(libraryProvider).value?.sort ?? SongSort.titleAsc;

  final selected = await showModalBottomSheet<SongSort>(
    context: context,
    showDragHandle: true,
    backgroundColor: colors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.sortLabel,
              style: AppTypography.sectionTitle.copyWith(
                color: colors.textHigh,
              ),
            ),
          ),
          RadioGroup<SongSort>(
            groupValue: current,
            onChanged: (value) => Navigator.of(sheetContext).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final sort in SongSort.values)
                  RadioListTile<SongSort>(
                    value: sort,
                    activeColor: colors.primary,
                    title: Text(_sortLabel(l10n, sort)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );

  if (selected != null) {
    ref.read(libraryProvider.notifier).setSort(selected);
    if (context.mounted) {
      showAppSnackBar(context, l10n.sortApplied(_sortLabel(l10n, selected)));
    }
  }
}

String _sortLabel(AppLocalizations l10n, SongSort sort) => switch (sort) {
  SongSort.titleAsc => l10n.sortByTitle,
  SongSort.artistAsc => l10n.sortByArtist,
  SongSort.albumAsc => l10n.sortByAlbum,
  SongSort.dateAddedDesc => l10n.sortByDateAdded,
  SongSort.durationDesc => l10n.sortByDuration,
  SongSort.sizeDesc => l10n.sortBySize,
  SongSort.trackAsc => l10n.sortByTrack,
};

Future<void> showFilterSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(libraryProvider).value?.filter ?? SongFilter.all;
  final selected = await showModalBottomSheet<SongFilter>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
    ),
    builder: (sheetContext) => SafeArea(
      child: RadioGroup<SongFilter>(
        groupValue: current,
        onChanged: (value) => Navigator.of(sheetContext).pop(value),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                context.l10n.filterTitle,
                style: AppTypography.sectionTitle.copyWith(
                  color: context.colors.textHigh,
                ),
              ),
            ),
            for (final filter in SongFilter.values)
              RadioListTile<SongFilter>(
                value: filter,
                activeColor: context.colors.primary,
                title: Text(_filterLabel(context.l10n, filter)),
              ),
          ],
        ),
      ),
    ),
  );
  if (selected != null) {
    ref.read(libraryProvider.notifier).setFilter(selected);
    if (context.mounted) {
      showAppSnackBar(context, context.l10n.filterApplied);
    }
  }
}

String _filterLabel(AppLocalizations l10n, SongFilter filter) =>
    switch (filter) {
      SongFilter.all => l10n.filterAll,
      SongFilter.missingMetadata => l10n.filterMissingMetadata,
      SongFilter.shortTracks => l10n.filterShortTracks,
      SongFilter.longTracks => l10n.filterLongTracks,
      SongFilter.lossless => l10n.filterLossless,
    };
