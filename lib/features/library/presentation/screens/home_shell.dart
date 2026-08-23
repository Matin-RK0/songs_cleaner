import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../screens/groups_tab.dart';
import '../screens/songs_tab.dart';

/// Home: tabs (songs / artists / albums), shuffle-all action and the mini
/// player docked at the bottom.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ref.listenManual(playbackErrorEventsProvider, (previous, next) {
      next.whenData((title) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          context.l10n.playbackFailedToast(title),
          error: true,
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCurrent =
        ref.watch(playerProvider.select((state) => state.hasCurrent));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.sortLabel,
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => showSortSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.songsTab),
              Tab(text: l10n.artistsTab),
              Tab(text: l10n.albumsTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SongsTab(),
                GroupsTab(isArtists: true),
                GroupsTab(isArtists: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final songs = ref.read(allSongsProvider);
          if (songs.isEmpty) return;
          final navigator = Navigator.of(context);
          await ref.read(playerProvider.notifier).playAllShuffled(songs);
          if (!mounted) return;
          navigator.pushNamed(RouteNames.player);
        },
        icon: const Icon(Icons.shuffle_rounded),
        label: Text(l10n.shuffleAll),
      ),
      bottomNavigationBar: hasCurrent ? const MiniPlayerBar() : null,
    );
  }
}
