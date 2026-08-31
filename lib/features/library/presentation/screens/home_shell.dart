import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/app_settings_repository.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../player/application/providers/notification_gate_controller.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../../player/presentation/widgets/notification_permission_banner.dart';
import '../screens/groups_tab.dart';
import '../screens/songs_tab.dart';
import '../../application/providers/library_controller.dart';

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

  @override
  void initState() {
    super.initState();
    final savedTab = ref
        .read(appSettingsRepositoryProvider)
        .loadHomeTabIndex(0)
        .clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: savedTab,
    );
    _songsScrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
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
    ref
        .read(appSettingsRepositoryProvider)
        .saveHomeTabIndex(_tabController.index);
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
    final l10n = context.l10n;
    final hasCurrent = ref.watch(
      playerProvider.select((state) => state.hasCurrent),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.searchHint,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.search),
          ),
          IconButton(
            tooltip: l10n.sortLabel,
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => showSortSheet(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: -8,
          ),
          tabs: [
            Tab(text: l10n.songsTab),
            Tab(text: l10n.artistsTab),
            Tab(text: l10n.albumsTab),
          ],
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
                    SongsTab(scrollController: _songsScrollController),
                    GroupsTab(isArtists: true),
                    GroupsTab(isArtists: false),
                  ],
                ),
              ),
            ],
          ),
          if (hasCurrent)
            const Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerBar(),
            ),
          PositionedDirectional(
            end: AppSpacing.md,
            bottom: hasCurrent
                ? MiniPlayerBar.height + AppSpacing.md
                : AppSpacing.md,
            child: FloatingActionButton(
              heroTag: 'shuffle-all',
              tooltip: l10n.shuffleAll,
              onPressed: () async {
                final songs = ref.read(allSongsProvider);
                if (songs.isEmpty) return;
                await ref.read(playerProvider.notifier).playAllShuffled(songs);
                if (!context.mounted) return;
                AppRouter.openPlayer(context);
              },
              child: const Icon(Icons.shuffle_rounded),
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
      ),
    );
  }

  void _scrollToCurrent() {
    final currentId = ref.read(playerProvider).current?.id;
    if (currentId == null) return;
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
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
}
