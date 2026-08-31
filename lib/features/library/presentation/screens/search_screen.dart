import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../application/providers/library_controller.dart';
import '../widgets/song_list_view.dart';

/// Search page styled after Blue Music's focused, full-screen search view.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.backTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.searchHint,
              border: InputBorder.none,
              filled: false,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        actions: [
          if (_query.trim().isNotEmpty)
            IconButton(
              tooltip: context.l10n.closeTooltip,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: library.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AppErrorState(
                title: context.l10n.errorLoadFailedTitle,
                message: context.l10n.errorLoadFailedMessage,
              ),
              data: (state) {
                final query = _query.trim().toLowerCase().replaceAll(' ', '');
                final songs = query.isEmpty
                    ? state.songs
                    : state.songs
                          .where((song) {
                            final title = song.title.toLowerCase().replaceAll(
                              ' ',
                              '',
                            );
                            final artist = song.artist.toLowerCase().replaceAll(
                              ' ',
                              '',
                            );
                            return title.contains(query) ||
                                artist.contains(query);
                          })
                          .toList(growable: false);
                if (songs.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: context.l10n.noResultsTitle,
                    message: context.l10n.noResultsMessage,
                  );
                }
                return SongListView(
                  songs: songs,
                  currentSongId: currentId,
                  physics: const BouncingScrollPhysics(),
                  onSongTap: (items, index) => ref
                      .read(playerProvider.notifier)
                      .playFromList(items, startIndex: index),
                );
              },
            ),
          ),
          if (currentId != null)
            const Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerBar(),
            ),
        ],
      ),
    );
  }
}
