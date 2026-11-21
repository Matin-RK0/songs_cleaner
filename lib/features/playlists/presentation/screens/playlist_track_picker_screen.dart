import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/alphabet_index_rail.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/playlist_picker_providers.dart';
import '../../application/providers/playlists_controller.dart';
import '../../domain/services/playlist_picker_catalog.dart';

class PlaylistTrackPickerScreen extends ConsumerStatefulWidget {
  const PlaylistTrackPickerScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<PlaylistTrackPickerScreen> createState() =>
      _PlaylistTrackPickerScreenState();
}

class _PlaylistTrackPickerScreenState
    extends ConsumerState<PlaylistTrackPickerScreen> {
  final _scroll = ScrollController(keepScrollOffset: false);
  final _search = TextEditingController();
  final _selected = <int>{};
  var _tab = PlaylistPickerTab.tracks;
  var _query = '';
  var _showSearch = false;
  var _saving = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _applyQuery(String query) {
    _debounce?.cancel();
    final normalized = query.trim().toLowerCase();
    if (_query == normalized) return;
    jumpToListRow(_scroll, 0);
    setState(() => _query = normalized);
  }

  void _toggle(Iterable<int> ids) => setState(() {
    if (ids.every(_selected.contains)) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
  });

  Future<void> _save() async {
    if (_saving || _selected.isEmpty) return;
    final ids = Set<int>.of(_selected);
    setState(() => _saving = true);
    await ref.read(playlistsProvider.notifier).addSongs(widget.playlistId, ids);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = ref.watch(
      playlistPickerViewProvider((widget.playlistId, _tab, _query)),
    );
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(hintText: l10n.searchHint),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(AppMotion.normal, () => _applyQuery(value));
                },
                onSubmitted: _applyQuery,
              )
            : Text(l10n.playlistSelectTracks),
        actions: [
          IconButton(
            tooltip: _showSearch ? l10n.cancel : l10n.searchHint,
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              if (_showSearch) {
                _search.clear();
                _applyQuery('');
              }
              setState(() => _showSearch = !_showSearch);
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screenPadding,
              child: Row(
                children: [
                  for (final (tab, label) in [
                    (PlaylistPickerTab.tracks, l10n.songsTab),
                    (PlaylistPickerTab.albums, l10n.albumsTab),
                    (PlaylistPickerTab.artists, l10n.artistsTab),
                    (PlaylistPickerTab.folders, l10n.foldersTab),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.sm,
                      ),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _tab == tab,
                        onSelected: (_) {
                          if (_tab == tab) return;
                          jumpToListRow(_scroll, 0);
                          setState(() => _tab = tab);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Material(
                color: context.colors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: AppRadius.radiusXlTopOnly,
                  ),
                ),
                child: view.rows.isEmpty
                    ? AppEmptyState(
                        icon: Icons.library_music_outlined,
                        title: _query.isEmpty
                            ? l10n.playlistPickerEmpty
                            : l10n.noResultsTitle,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scroll,
                              physics: const ClampingScrollPhysics(),
                              itemExtent: AppSpacing.trackRowHeight,
                              padding: EdgeInsets.zero,
                              itemCount: view.rows.length,
                              itemBuilder: (_, index) {
                                final row = view.rows[index];
                                final track = _tab == PlaylistPickerTab.tracks;
                                final checked =
                                    row.ids.every(_selected.contains)
                                    ? true
                                    : row.ids.any(_selected.contains)
                                    ? null
                                    : false;
                                return CheckboxListTile(
                                  key: ValueKey(row.key),
                                  value: checked,
                                  tristate: true,
                                  onChanged: (_) => _toggle(row.ids),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  secondary: ArtworkImage(
                                    songId: row.cover.id,
                                    size: AppSpacing.avatarSize,
                                    borderRadius: AppRadius.md,
                                  ),
                                  title: Text(
                                    row.title.isEmpty
                                        ? l10n.unknownValue
                                        : row.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    track
                                        ? (row.cover.artist.isEmpty
                                              ? l10n.unknownArtist
                                              : row.cover.artist)
                                        : l10n.songCountLabel(row.ids.length),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          AlphabetIndexRail(
                            index: view.alphabet,
                            onJump: (row) => jumpToListRow(
                              _scroll,
                              row * AppSpacing.trackRowHeight,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.allSm,
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.selectAll,
              icon: const Icon(Icons.select_all_rounded),
              onPressed: view.ids.isEmpty || _saving
                  ? null
                  : () => _toggle(view.ids),
            ),
            Expanded(
              child: Text(
                l10n.selectedCount(_selected.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: FilledButton(
                onPressed: _selected.isEmpty || _saving ? null : _save,
                child: Text(
                  l10n.playlistAddTracks,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
