import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/domain/entities/song.dart';
import '../../application/providers/playlist_providers.dart';
import '../../application/providers/playlists_controller.dart';
import '../../application/playlist_transfer_service.dart';
import '../../domain/entities/smart_playlist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/playlist_order.dart';
import '../widgets/playlist_artwork.dart';
import '../widgets/playlist_card.dart';
import '../widgets/playlist_name_sheet.dart';
import '../widgets/playlist_sort_button.dart';
import '../widgets/smart_playlist_presentation.dart';

/// Playlists tab: smart playlists (derived) plus the user's custom playlists.
class PlaylistsTab extends ConsumerStatefulWidget {
  const PlaylistsTab({super.key, this.bottomOverlayInset = 0});

  final double bottomOverlayInset;

  @override
  ConsumerState<PlaylistsTab> createState() => _PlaylistsTabState();
}

enum _TransferAction { import, export, share }

class _PlaylistsTabState extends ConsumerState<PlaylistsTab> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;
  var _query = '';
  var _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = ref.watch(playlistListOrderProvider);
    final view = ref.watch(playlistBrowseProvider((order, _query)));
    return Material(
      color: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXlTopOnly),
      ),
      child: CustomScrollView(
        controller: _scroll,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _SectionHeader(title: l10n.smartPlaylistsSection),
                _SmartPlaylists(onOpen: (kind) => _openSmart(context, kind)),
                _SectionHeader(
                  title: l10n.myPlaylistsSection,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (view.hasPlaylists)
                        IconButton(
                          tooltip: _searching
                              ? l10n.closeTooltip
                              : l10n.searchHint,
                          icon: Icon(
                            _searching
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                          ),
                          onPressed: _toggleSearch,
                        ),
                      IconButton(
                        tooltip: l10n.newPlaylist,
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () => _createPlaylist(context, ref),
                      ),
                      PopupMenuButton<_TransferAction>(
                        tooltip: l10n.moreActions,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _TransferAction.import,
                            child: Text(l10n.importPlaylists),
                          ),
                          PopupMenuItem(
                            value: _TransferAction.export,
                            enabled: view.hasPlaylists,
                            child: Text(l10n.exportPlaylists),
                          ),
                          PopupMenuItem(
                            value: _TransferAction.share,
                            enabled: view.hasPlaylists,
                            child: Text(l10n.sharePlaylists),
                          ),
                        ],
                        onSelected: (action) {
                          final songs = ref.read(allSongsProvider);
                          final playlists = ref.read(playlistsProvider);
                          switch (action) {
                            case _TransferAction.import:
                              _importPlaylists(context, ref, songs);
                            case _TransferAction.export:
                              _exportPlaylists(context, playlists, songs);
                            case _TransferAction.share:
                              _sharePlaylists(context, playlists, songs);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (_searching)
                  Padding(
                    padding: AppSpacing.hMdVSm,
                    child: TextField(
                      controller: _search,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          AppMotion.normal,
                          () => _applyQuery(value),
                        );
                      },
                      onSubmitted: _applyQuery,
                    ),
                  ),
                if (view.hasPlaylists)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: PlaylistSortButton(
                        current: order,
                        options: PlaylistListOrder.values,
                        labelOf: (order) => playlistListOrderLabel(l10n, order),
                        onSelected: ref
                            .read(playlistListOrderProvider.notifier)
                            .setOrder,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!view.hasPlaylists)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  AppEmptyState(
                    icon: Icons.queue_music_rounded,
                    title: l10n.playlistsEmptyTitle,
                    message: l10n.playlistsEmptyMessage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryActionButton(
                    label: l10n.newPlaylist,
                    icon: Icons.add_rounded,
                    onPressed: () => _createPlaylist(context, ref),
                  ),
                ],
              ),
            )
          else if (view.rows.isEmpty)
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: l10n.noResultsTitle,
              ),
            )
          else
            SliverFixedExtentList.builder(
              itemExtent: AppSpacing.trackRowHeight,
              itemCount: view.rows.length,
              itemBuilder: (context, index) => _CustomPlaylistRow(
                playlist: view.rows[index],
                onTap: () => _openCustom(context, view.rows[index].id),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: widget.bottomOverlayInset + AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  void _applyQuery(String value) {
    _debounce?.cancel();
    final query = value.trim().toLowerCase();
    if (query != _query) setState(() => _query = query);
  }

  void _toggleSearch() {
    _debounce?.cancel();
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search.clear();
        _query = '';
      }
    });
  }

  void _openCustom(BuildContext context, String playlistId) {
    Navigator.of(context).pushNamed(
      RouteNames.playlistDetail,
      arguments: PlaylistDetailArgs.custom(playlistId),
    );
  }

  void _openSmart(BuildContext context, SmartPlaylistKind kind) {
    Navigator.of(context).pushNamed(
      RouteNames.playlistDetail,
      arguments: PlaylistDetailArgs.smart(kind),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showPlaylistNameSheet(
      context: context,
      title: l10n.newPlaylist,
      actionLabel: l10n.createAction,
    );
    if (name == null || !context.mounted) return;
    final playlist = await ref.read(playlistsProvider.notifier).create(name);
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.playlistCreatedToast(playlist.name));
    _openCustom(context, playlist.id);
  }

  Future<void> _exportPlaylists(
    BuildContext context,
    List<Playlist> playlists,
    List<Song> songs,
  ) async {
    try {
      final exported = await const PlaylistTransferService().exportToFile(
        playlists,
        songs,
      );
      if (exported && context.mounted) {
        showAppSnackBar(context, context.l10n.playlistsExported);
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

  Future<void> _importPlaylists(
    BuildContext context,
    WidgetRef ref,
    List<Song> songs,
  ) async {
    final importedPlaylistName = context.l10n.importedPlaylistName;
    try {
      final imported = await const PlaylistTransferService().importFromFile();
      if (imported == null || !context.mounted) return;
      final count = await ref
          .read(playlistsProvider.notifier)
          .importPlaylists(imported, songs, importedPlaylistName);
      if (context.mounted) {
        showAppSnackBar(context, context.l10n.playlistsImported(count));
      }
    } on FormatException {
      if (context.mounted) {
        showAppSnackBar(context, context.l10n.playlistFileInvalid, error: true);
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

  Future<void> _sharePlaylists(
    BuildContext context,
    List<Playlist> playlists,
    List<Song> songs,
  ) async {
    try {
      final shared = await const PlaylistTransferService().sharePlaylists(
        playlists,
        songs,
      );
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

/// Section title with an optional trailing action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: context.colors.textHigh,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SmartPlaylists extends StatelessWidget {
  const _SmartPlaylists({required this.onOpen});

  final ValueChanged<SmartPlaylistKind> onOpen;

  static const _width = AppSpacing.avatarLarge * 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          _width +
          MediaQuery.textScalerOf(context)
              .scale(AppSpacing.xl + AppSpacing.md) +
          AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: AppSpacing.screenPadding,
        itemCount: SmartPlaylistKind.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final kind = SmartPlaylistKind.values[index];
          return SizedBox(
            width: _width,
            child: Consumer(
              builder: (context, ref, _) {
                final songs = ref.watch(smartPlaylistSongsProvider(kind));
                return PlaylistCard(
                  title: kind.title(context.l10n),
                  subtitle: context.l10n.songCountLabel(songs.length),
                  cover: PlaylistArtwork(
                    songIds: [if (songs.isNotEmpty) songs.first.id],
                    size: _width,
                    expand: true,
                    placeholderIcon: kind.icon,
                  ),
                  onTap: () => onOpen(kind),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomPlaylistRow extends StatelessWidget {
  const _CustomPlaylistRow({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: AppSpacing.screenPadding,
    leading: PlaylistArtwork(
      songIds: playlist.songIds,
      coverPath: playlist.coverPath,
      size: AppSpacing.avatarSize,
      heroTag: 'playlist-art-${playlist.id}',
    ),
    title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      context.l10n.songCountLabel(playlist.songCount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Icon(
      playlist.isFavorite
          ? Icons.favorite_rounded
          : Icons.chevron_right_rounded,
      color: playlist.isFavorite
          ? context.colors.danger
          : context.colors.textLow,
    ),
  );
}
