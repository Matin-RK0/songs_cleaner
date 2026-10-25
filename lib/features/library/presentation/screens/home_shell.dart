import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/home_tab_settings.dart';
import '../../../../core/settings/home_tab_settings_controller.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../player/application/providers/notification_gate_controller.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../../player/presentation/widgets/notification_permission_banner.dart';
import '../../../playlists/application/providers/playlists_controller.dart';
import '../../../playlists/presentation/screens/playlists_tab.dart';
import '../../../playlists/presentation/widgets/playlist_name_sheet.dart';
import '../../../telegram/presentation/screens/telegram_tab.dart';
import '../screens/groups_tab.dart';
import '../screens/songs_tab.dart';
import '../models/home_tab_presentation.dart';
import '../../application/providers/library_controller.dart';
import '../../application/providers/library_sync_scheduler.dart';

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
  late final ScrollController _songsScrollController;
  AppLifecycleListener? _lifecycleListener;
  late int _lastTabIndex;
  late List<HomeTab> _tabs;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(homeTabSettingsProvider);
    _tabs = settings.order;
    final savedTab = _tabs.indexOf(settings.defaultTab);
    _lastTabIndex = savedTab;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: savedTab,
    );
    _songsScrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    ref.listenManual(homeTabSettingsProvider, (_, settings) {
      final activeTab = _tabs[_tabController.index];
      setState(() {
        _tabs = settings.order;
        _lastTabIndex = _tabs.indexOf(activeTab);
        _tabController.index = _lastTabIndex;
      });
    });
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

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    // Swap the floating action (shuffle vs. new playlist) for the active tab.
    setState(() {});
  }

  Future<void> _createPlaylist() async {
    final l10n = context.l10n;
    final name = await showPlaylistNameSheet(
      context: context,
      title: l10n.newPlaylist,
      actionLabel: l10n.createAction,
    );
    if (name == null) return;
    final playlist = await ref.read(playlistsProvider.notifier).create(name);
    if (!mounted) return;
    showAppSnackBar(context, l10n.playlistCreatedToast(playlist.name));
  }

  Future<void> _refreshLibrary() async {
    try {
      await ref.read(libraryProvider.notifier).refresh();
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.actionFailedGeneric, error: true);
      return;
    }
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.librarySyncedToast);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-evaluate the notification permission when the user comes back from
    // the system settings page.
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () {
        final gate = ref.read(notificationGateProvider.notifier);
        gate.recheck();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _songsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the periodic new-song scan alive for the whole session.
    ref.watch(librarySyncSchedulerProvider);
    final l10n = context.l10n;
    final hasCurrent = ref.watch(
      playerProvider.select((state) => state.hasCurrent),
    );
    final activeTab = _tabs[_tabController.index];
    final onPlaylistsTab = activeTab == HomeTab.playlists;
    final onTelegramTab = activeTab == HomeTab.telegram;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.searchHint,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.search),
          ),
          PopupMenuButton<_HomeAction>(
            tooltip: l10n.moreActions,
            onSelected: (action) =>
                _runHomeAction(action, onPlaylistsTab || onTelegramTab),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _HomeAction.refresh,
                child: ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(l10n.refreshLibraryTooltip),
                ),
              ),
              if (!onPlaylistsTab && !onTelegramTab) ...[
                PopupMenuItem(
                  value: _HomeAction.filter,
                  child: ListTile(
                    leading: const Icon(Icons.filter_alt_outlined),
                    title: Text(l10n.filterTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _HomeAction.sort,
                  child: ListTile(
                    leading: const Icon(Icons.sort_rounded),
                    title: Text(l10n.sortLabel),
                  ),
                ),
              ],
              PopupMenuItem(
                value: _HomeAction.insights,
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(l10n.libraryInsightsTitle),
                ),
              ),
              PopupMenuItem(
                value: _HomeAction.settings,
                child: ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: Text(l10n.settingsTitle),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: -8),
          tabs: [for (final tab in _tabs) Tab(text: tab.label(l10n))],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const NotificationPermissionBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final tab in _tabs)
                      KeyedSubtree(
                        key: ValueKey(tab),
                        child: switch (tab) {
                          HomeTab.songs => SongsTab(
                            scrollController: _songsScrollController,
                          ),
                          HomeTab.artists => GroupsTab(isArtists: true),
                          HomeTab.albums => GroupsTab(isArtists: false),
                          HomeTab.playlists => const PlaylistsTab(),
                          HomeTab.telegram => const TelegramTab(),
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedPositionedDirectional(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            start: 0,
            end: 0,
            bottom: hasCurrent ? 0 : -MiniPlayerBar.height,
            child: const MiniPlayerBar(),
          ),
          if (onPlaylistsTab)
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: hasCurrent
                  ? MiniPlayerBar.height + AppSpacing.md
                  : AppSpacing.md,
              child: FloatingActionButton(
                heroTag: 'new-playlist',
                tooltip: l10n.newPlaylist,
                onPressed: _createPlaylist,
                child: const Icon(Icons.add_rounded),
              ),
            )
          else if (!onTelegramTab) ...[
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: hasCurrent
                  ? MiniPlayerBar.height + AppSpacing.md
                  : AppSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeTab == HomeTab.songs) ...[
                    FloatingActionButton.small(
                      heroTag: 'scroll-to-top',
                      tooltip: l10n.scrollToTop,
                      onPressed: _scrollToTop,
                      child: const Icon(Icons.vertical_align_top_rounded),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FloatingActionButton(
                    heroTag: 'shuffle-all',
                    tooltip: l10n.shuffleAll,
                    onPressed: () async {
                      final songs = ref.read(allSongsProvider);
                      if (songs.isEmpty) return;
                      await ref
                          .read(playerProvider.notifier)
                          .playAllShuffled(songs);
                      if (!context.mounted) return;
                      AppRouter.openPlayer(context);
                    },
                    child: const Icon(Icons.shuffle_rounded),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              end: AppSpacing.md + 64,
              bottom: hasCurrent
                  ? MiniPlayerBar.height + AppSpacing.md
                  : AppSpacing.md,
              child: FloatingActionButton.small(
                heroTag: 'scroll-to-current',
                tooltip: l10n.nowPlaying,
                onPressed: _scrollToCurrent,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _scrollToTop() {
    if (!_songsScrollController.hasClients) return;
    final target = _songsScrollController.position.minScrollExtent;
    if (MediaQuery.disableAnimationsOf(context)) {
      _songsScrollController.jumpTo(target);
      return;
    }
    _songsScrollController.animateTo(
      target,
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );
  }

  void _scrollToCurrent() {
    final currentId = ref.read(playerProvider).current?.id;
    if (currentId == null) return;
    final songsIndex = _tabs.indexOf(HomeTab.songs);
    if (_tabController.index != songsIndex) {
      _tabController.animateTo(songsIndex);
    }
    final songs = ref.read(libraryProvider).value?.visibleSongs ?? const [];
    final index = songs.indexWhere((song) => song.id == currentId);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_songsScrollController.hasClients) return;
      final target = (index * 76.0).clamp(
        0.0,
        _songsScrollController.position.maxScrollExtent,
      );
      _songsScrollController.animateTo(
        target,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    });
  }

  void _runHomeAction(_HomeAction action, bool onPlaylistsTab) {
    switch (action) {
      case _HomeAction.refresh:
        _refreshLibrary();
        return;
      case _HomeAction.filter:
        if (!onPlaylistsTab) showFilterSheet(context, ref);
        return;
      case _HomeAction.sort:
        if (!onPlaylistsTab) showSortSheet(context, ref);
        return;
      case _HomeAction.settings:
        Navigator.of(context).pushNamed(RouteNames.settings);
        return;
      case _HomeAction.insights:
        Navigator.of(context).pushNamed(RouteNames.libraryInsights);
        return;
    }
  }
}

enum _HomeAction { refresh, filter, sort, insights, settings }
